import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avalia/core/state/base_state.dart';
import 'package:avalia/data/models/submission_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubmissionCubit extends Cubit<BaseState> {
  final SupabaseClient _supabase = Supabase.instance.client;

  SubmissionCubit() : super(InitialState());

  /// Buscar submissão existente para uma prova específica
  Future<void> getSubmission(String provaId, String alunoId) async {
    try {
      emit(LoadingState());

      final response = await _supabase
          .from('submissoes')
          .select()
          .eq('prova_id', provaId)
          .eq('aluno_id', alunoId)
          .maybeSingle();

      if (response == null) {
        emit(SuccessState<SubmissionModel?>(null));
      } else {
        final submission = SubmissionModel.fromJson(response);
        emit(SuccessState<SubmissionModel>(submission));
      }
    } catch (e) {
      emit(ErrorState('Erro ao buscar submissão: $e'));
    }
  }

  /// Validação pré-upload (cliente)
  Future<ValidationResult> validateImage(File imageFile) async {
    try {
      // Verificar tamanho do arquivo (< 8MB)
      final fileSize = await imageFile.length();
      if (fileSize > 8 * 1024 * 1024) {
        return ValidationResult(
          isValid: false,
          error: 'Imagem muito grande. Tamanho máximo: 8MB',
        );
      }

      // Verificar tipo de arquivo
      final fileName = imageFile.path.toLowerCase();
      if (!fileName.endsWith('.jpg') &&
          !fileName.endsWith('.jpeg') &&
          !fileName.endsWith('.png')) {
        return ValidationResult(
          isValid: false,
          error: 'Formato inválido. Use JPG ou PNG',
        );
      }

      // TODO: Adicionar verificação de resolução mínima se necessário
      // Isso requer package adicional como image ou flutter_image_compress

      return ValidationResult(isValid: true);
    } catch (e) {
      return ValidationResult(
        isValid: false,
        error: 'Erro ao validar imagem: $e',
      );
    }
  }

  /// Criar submissão placeholder e fazer upload
  Future<void> uploadSubmission({
    required String provaId,
    required String alunoId,
    required File imageFile,
    int attemptNumber = 1,
  }) async {
    try {
      emit(SubmissionUploadingState(0));

      // 1. Validação pré-upload
      final validation = await validateImage(imageFile);
      if (!validation.isValid) {
        emit(
          SubmissionErrorState(
            validation.error ?? 'Validação falhou',
            'VALIDATION_ERROR',
          ),
        );
        return;
      }

      // 2. Upload da imagem para Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$provaId/$alunoId/$timestamp.jpg';

      emit(SubmissionUploadingState(25));

      final uploadPath = await _supabase.storage
          .from('exam-submissions')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      emit(SubmissionUploadingState(50));

      // 3. Obter URL pública da imagem
      final imageUrl = _supabase.storage
          .from('exam-submissions')
          .getPublicUrl(fileName);

      emit(SubmissionUploadingState(75));

      // 4. Criar registro de submissão no banco
      final submissionData = {
        'prova_id': provaId,
        'aluno_id': alunoId,
        'image_url': imageUrl,
        'status': SubmissionStatus.processingUpload.value,
        'uploaded_at': DateTime.now().toIso8601String(),
        'attempt_number': attemptNumber,
      };

      final response = await _supabase
          .from('submissoes')
          .insert(submissionData)
          .select()
          .single();

      emit(SubmissionUploadingState(100));

      final submission = SubmissionModel.fromJson(response);

      // 5. Transição para estado de processamento
      emit(SubmissionProcessingState('analysis', submission));

      // 6. Aqui o webhook/n8n será acionado automaticamente
      // via trigger do Supabase ou chamada explícita
    } catch (e) {
      if (e is StorageException) {
        emit(
          SubmissionErrorState('Erro no upload: ${e.message}', 'UPLOAD_ERROR'),
        );
      } else {
        emit(
          SubmissionErrorState(
            'Erro ao criar submissão: $e',
            'SUBMISSION_ERROR',
          ),
        );
      }
    }
  }

  /// Solicitar reprocessamento manual
  Future<void> requestReprocessing(String submissionId) async {
    try {
      emit(LoadingState());

      // Chamar função RPC ou endpoint específico para reprocessamento
      await _supabase.rpc(
        'reprocess_submission',
        params: {'submission_id': submissionId},
      );

      // Buscar submissão atualizada
      final response = await _supabase
          .from('submissoes')
          .select()
          .eq('id', submissionId)
          .single();

      final submission = SubmissionModel.fromJson(response);
      emit(SubmissionProcessingState('reprocessing', submission));
    } catch (e) {
      emit(ErrorState('Erro ao solicitar reprocessamento: $e'));
    }
  }

  /// Forçar aceitação (override) - apenas para professores
  Future<void> forceAcceptSubmission(String submissionId) async {
    try {
      emit(LoadingState());

      final response = await _supabase
          .from('submissoes')
          .update({
            'status': SubmissionStatus.graded.value,
            'finished_at': DateTime.now().toIso8601String(),
          })
          .eq('id', submissionId)
          .select()
          .single();

      final submission = SubmissionModel.fromJson(response);
      emit(SubmissionCompletedState(submission));
    } catch (e) {
      emit(ErrorState('Erro ao forçar aceitação: $e'));
    }
  }

  /// Escutar atualizações em tempo real da submissão
  void subscribeToSubmissionUpdates(String submissionId) {
    _supabase
        .channel('submission_$submissionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'submissoes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: submissionId,
          ),
          callback: (payload) {
            final submission = SubmissionModel.fromJson(
              payload.newRecord as Map<String, dynamic>,
            );
            _handleSubmissionUpdate(submission);
          },
        )
        .subscribe();
  }

  void _handleSubmissionUpdate(SubmissionModel submission) {
    switch (submission.status) {
      case SubmissionStatus.processingAnalysis:
        emit(SubmissionProcessingState('analysis', submission));
        break;
      case SubmissionStatus.aiValidation:
        emit(SubmissionProcessingState('ai_validation', submission));
        break;
      case SubmissionStatus.reviewNeeded:
        emit(SubmissionNeedsReviewState(submission.issues ?? [], submission));
        break;
      case SubmissionStatus.graded:
        emit(SubmissionCompletedState(submission));
        break;
      case SubmissionStatus.error:
        emit(SubmissionErrorState('Erro no processamento', 'PROCESSING_ERROR'));
        break;
      default:
        emit(SuccessState<SubmissionModel>(submission));
    }
  }

  void resetToInitial() {
    emit(InitialState());
  }
}

// Estados específicos de submissão
class SubmissionPickingState extends BaseState {}

class SubmissionPreviewState extends BaseState {
  final File imageFile;
  SubmissionPreviewState(this.imageFile);
}

class SubmissionUploadingState extends BaseState {
  final int percent;
  SubmissionUploadingState(this.percent);
}

class SubmissionProcessingState extends BaseState {
  final String step; // 'analysis', 'ai_validation', 'grading', 'reprocessing'
  final SubmissionModel submission;

  SubmissionProcessingState(this.step, this.submission);
}

class SubmissionNeedsReviewState extends BaseState {
  final List<SubmissionIssue> issues;
  final SubmissionModel submission;

  SubmissionNeedsReviewState(this.issues, this.submission);
}

class SubmissionCompletedState extends BaseState {
  final SubmissionModel submission;
  SubmissionCompletedState(this.submission);
}

class SubmissionErrorState extends BaseState {
  final String message;
  final String code;

  SubmissionErrorState(this.message, this.code);
}

// Resultado de validação
class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult({required this.isValid, this.error});
}
