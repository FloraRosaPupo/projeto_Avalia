import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:Avalia/core/state/base_state.dart';
import 'package:Avalia/data/models/submission_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubmissionCubit extends Cubit<BaseState> {
  final SupabaseClient _supabase = Supabase.instance.client;

  SubmissionCubit() : super(InitialState());

  /// Helper para converter String para int com segurança
  int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Buscar submissão existente para uma prova específica
  Future<void> getSubmission(String provaId, String alunoId) async {
    try {
      emit(LoadingState());

      // Converter para int conforme schema do banco (bigint)
      final provaIdInt = _parseToInt(provaId);
      final alunoIdInt = _parseToInt(alunoId);

      if (provaIdInt == null || alunoIdInt == null) {
        print(
          'ERROR: provaId ou alunoId inválidos: provaId=$provaId, alunoId=$alunoId',
        );
        emit(ErrorState('IDs inválidos: provaId=$provaId, alunoId=$alunoId'));
        return;
      }

      print(
        'DEBUG: Buscando submissão - provaId: $provaIdInt (tipo: ${provaIdInt.runtimeType}), alunoId: $alunoIdInt (tipo: ${alunoIdInt.runtimeType})',
      );

      final response = await _supabase
          .from('submissoes')
          .select()
          .eq('prova_id', provaIdInt)
          .eq('aluno_id', alunoIdInt)
          .maybeSingle();

      print('Submission response: $response');

      if (response == null) {
        print('No submission found.');
        emit(SuccessState<SubmissionModel?>(null));
      } else {
        final submission = SubmissionModel.fromJson(response);
        print('Submission parsed successfully: ${submission.id}');
        emit(SuccessState<SubmissionModel>(submission));
      }
    } catch (e, s) {
      print('Error fetching submission: $e');
      print('Stack trace: $s');
      emit(ErrorState('Erro ao buscar submissão: $e'));
    }
  }

  void updateSubmission(SubmissionModel submission) {
    emit(SuccessState<SubmissionModel>(submission));
  }

  /// Validação pré-upload (cliente)
  Future<ValidationResult> validateImage(File imageFile) async {
    try {
      // Verificar tamanho do arquivo (< 50MB)
      final fileSize = await imageFile.length();
      const maxSize = 50 * 1024 * 1024; // 50MB in bytes
      if (fileSize > maxSize) {
        return ValidationResult(
          isValid: false,
          error: 'Arquivo muito grande. Tamanho máximo: 50MB',
        );
      }

      // Verificar tipo de arquivo - mais flexível para imagens da galeria
      final fileName = imageFile.path.toLowerCase();
      final hasValidExtension =
          fileName.endsWith('.jpg') ||
          fileName.endsWith('.jpeg') ||
          fileName.endsWith('.png') ||
          fileName.endsWith('.heic') ||
          fileName.endsWith('.heif') ||
          fileName.endsWith('.webp');

      // Se não tem extensão válida, aceita mesmo assim
      // O ImagePicker já faz conversão de formatos (HEIC, HEIF, etc) para JPEG
      // e imagens da galeria podem não ter extensão no caminho
      if (!hasValidExtension) {
        print(
          'WARNING: Arquivo sem extensão conhecida, mas aceitando (ImagePicker faz conversão)',
        );
      }

      return ValidationResult(isValid: true);
    } catch (e) {
      print('ERROR: Erro ao validar imagem: $e');
      // Se houver erro na validação, aceita o arquivo (o servidor fará validação final)
      // Isso evita rejeitar imagens válidas por problemas na validação local
      return ValidationResult(isValid: true);
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

      // 2. Converter IDs para int conforme schema do banco
      final provaIdInt = _parseToInt(provaId);
      final alunoIdInt = _parseToInt(alunoId);

      if (provaIdInt == null || alunoIdInt == null) {
        emit(
          SubmissionErrorState(
            'IDs inválidos: provaId=$provaId, alunoId=$alunoId',
            'INVALID_IDS',
          ),
        );
        return;
      }

      // 3. Upload da imagem para Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$provaIdInt/$alunoIdInt/$timestamp.jpg';

      emit(SubmissionUploadingState(25));

      await _supabase.storage
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

      // 4. Verificar se já existe submissão para esta prova/aluno
      final existingSubmission = await _supabase
          .from('submissoes')
          .select()
          .eq('prova_id', provaIdInt)
          .eq('aluno_id', alunoIdInt)
          .maybeSingle();

      // 6. Atualizar ou criar registro de submissão no banco
      final submissionData = {
        'prova_id': provaIdInt,
        'aluno_id': alunoIdInt,
        'image_url': imageUrl,
        'status': SubmissionStatus.processingUpload.value,
        'attempt_number': attemptNumber,
      };

      late final Map<String, dynamic> response;

      try {
        if (existingSubmission != null) {
          // UPDATE submissão existente
          response = await _supabase
              .from('submissoes')
              .update(submissionData)
              .eq('id', existingSubmission['id'])
              .select()
              .single();
        } else {
          // INSERT nova submissão
          response = await _supabase
              .from('submissoes')
              .insert(submissionData)
              .select()
              .single();
        }
      } catch (e) {
        // Se o erro for sobre coluna não existir, tenta sem attempt_number
        if (e.toString().contains('attempt_number') ||
            e.toString().contains('column') ||
            e.toString().contains('does not exist')) {
          print('WARNING: Coluna attempt_number não existe, tentando sem ela');

          final fallbackData = Map<String, dynamic>.from(submissionData);
          fallbackData.remove('attempt_number');

          if (existingSubmission != null) {
            // UPDATE sem attempt_number
            response = await _supabase
                .from('submissoes')
                .update(fallbackData)
                .eq('id', existingSubmission['id'])
                .select()
                .single();
          } else {
            // INSERT sem attempt_number
            response = await _supabase
                .from('submissoes')
                .insert(fallbackData)
                .select()
                .single();
          }
        } else {
          rethrow;
        }
      }

      emit(SubmissionUploadingState(100));

      final submission = SubmissionModel.fromJson(response);

      // 5. Transição para estado de processamento
      emit(SubmissionProcessingState('analysis', submission));
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
            try {
              final record = payload.newRecord;
              final submissionData = Map<String, dynamic>.from(record);
              final submission = SubmissionModel.fromJson(submissionData);
              _handleSubmissionUpdate(submission);
            } catch (e, stackTrace) {
              print('ERROR: Erro ao processar atualização em tempo real: $e');
              print('ERROR: StackTrace: $stackTrace');
            }
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

  /// Submeter e corrigir automaticamente com IA via Edge Function
  Future<void> submitAndAutoCorrect({
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

      // 2. Converter IDs para int conforme schema do banco
      final provaIdInt = _parseToInt(provaId);
      final alunoIdInt = _parseToInt(alunoId);

      if (provaIdInt == null || alunoIdInt == null) {
        emit(
          SubmissionErrorState(
            'IDs inválidos: provaId=$provaId, alunoId=$alunoId',
            'INVALID_IDS',
          ),
        );
        return;
      }

      print(
        'DEBUG: submitAndAutoCorrect - provaId: $provaIdInt (int), alunoId: $alunoIdInt (int)',
      );

      // 3. Verificar se já existe submissão para esta prova/aluno
      final existingSubmission = await _supabase
          .from('submissoes')
          .select('id')
          .eq('prova_id', provaIdInt)
          .eq('aluno_id', alunoIdInt)
          .maybeSingle();

      // 4. Upload da imagem
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$provaIdInt/$alunoIdInt/$timestamp.jpg';
      emit(SubmissionUploadingState(20));

      await _supabase.storage
          .from('exam-submissions')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      emit(SubmissionUploadingState(50));

      final imageUrl = _supabase.storage
          .from('exam-submissions')
          .getPublicUrl(fileName);
      emit(SubmissionUploadingState(80));

      // 4. Buscar metadados da prova (Gabarito)
      final examData = await _supabase
          .from('provas')
          .select('url_prova')
          .eq('id', provaIdInt)
          .single();

      final gabaritoUrl = examData['url_prova'] as String?;

      emit(SubmissionUploadingState(100));

      // 5. Atualizar ou criar submissão no banco
      String submissionId;
      if (existingSubmission != null) {
        // UPDATE submissão existente
        // ID pode vir como int (bigint) ou String do banco
        final idValue = existingSubmission['id'];
        submissionId = idValue is int
            ? idValue.toString()
            : (idValue as String? ?? '');

        try {
          await _supabase
              .from('submissoes')
              .update({
                'image_url': imageUrl,
                'status': SubmissionStatus.processingAnalysis.value,
                'attempt_number': attemptNumber,
              })
              .eq('id', submissionId);
        } catch (e) {
          // Se o erro for sobre coluna não existir, tenta sem attempt_number
          if (e.toString().contains('attempt_number') ||
              e.toString().contains('column') ||
              e.toString().contains('does not exist')) {
            print(
              'WARNING: Coluna attempt_number não existe, tentando UPDATE sem ela',
            );

            await _supabase
                .from('submissoes')
                .update({
                  'image_url': imageUrl,
                  'status': SubmissionStatus.processingAnalysis.value,
                })
                .eq('id', submissionId);
          } else {
            rethrow;
          }
        }
      } else {
        // INSERT nova submissão
        final submissionData = {
          'prova_id': provaIdInt,
          'aluno_id': alunoIdInt,
          'image_url': imageUrl,
          'status': SubmissionStatus.processingAnalysis.value,
          'attempt_number': attemptNumber,
        };

        Map<String, dynamic> response;

        try {
          response = await _supabase
              .from('submissoes')
              .insert(submissionData)
              .select()
              .single();
        } catch (e) {
          // Se o erro for sobre coluna não existir, tenta sem attempt_number
          if (e.toString().contains('attempt_number') ||
              e.toString().contains('column') ||
              e.toString().contains('does not exist')) {
            print(
              'WARNING: Coluna attempt_number não existe, tentando INSERT sem ela',
            );

            final fallbackData = Map<String, dynamic>.from(submissionData);
            fallbackData.remove('attempt_number');

            response = await _supabase
                .from('submissoes')
                .insert(fallbackData)
                .select()
                .single();
          } else {
            rethrow;
          }
        }

        // ID pode vir como int (bigint) ou String do banco
        final idValue = response['id'];
        submissionId = idValue is int
            ? idValue.toString()
            : (idValue as String? ?? '');
      }

      // Criar modelo temporário para UI
      var submission = SubmissionModel(
        provaId: provaId,
        alunoId: alunoId,
        imageUrl: imageUrl,
        status: SubmissionStatus.processingAnalysis,
        attemptNumber: attemptNumber,
      );

      // 6. Chamar Edge Function
      emit(SubmissionProcessingState('analysis', submission));

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      final functionResponse = await _supabase.functions.invoke(
        'quick-api',
        body: {
          'provaId': provaIdInt,
          'alunoId': alunoIdInt,
          'image_url': imageUrl,
          'gabarito_url': gabaritoUrl,
          'userId': userId,
          'submission_id':
              submissionId, // Passar ID para a função saber qual atualizar
        },
      );

      if (functionResponse.status != 200) {
        throw Exception(
          'Erro na Edge Function: ${functionResponse.status} - ${functionResponse.data}',
        );
      }

      final responseData = functionResponse.data;
      if (responseData['error'] != null) {
        throw Exception(responseData['error']);
      }

      // 5. Processar resultado retornado pela função
      // A função retorna o objeto de submissão atualizado
      try {
        print('DEBUG: Response data type: ${responseData.runtimeType}');
        print('DEBUG: Response data: $responseData');

        // Garante que responseData é um Map
        Map<String, dynamic> submissionData;
        if (responseData is Map<String, dynamic>) {
          submissionData = responseData;
        } else if (responseData is Map) {
          submissionData = Map<String, dynamic>.from(responseData);
        } else {
          throw Exception(
            'Resposta da função não é um objeto válido: ${responseData.runtimeType}',
          );
        }

        final finalSubmission = SubmissionModel.fromJson(submissionData);
        print('DEBUG: Submission parseado com sucesso: ${finalSubmission.id}');

        emit(SubmissionCompletedState(finalSubmission));
      } catch (parseError, stackTrace) {
        print('ERROR: Erro ao fazer parse da resposta: $parseError');
        print('ERROR: StackTrace: $stackTrace');
        print('ERROR: ResponseData: $responseData');
        emit(
          SubmissionErrorState(
            'Erro ao processar resultado: $parseError',
            'PARSE_ERROR',
          ),
        );
      }
    } catch (e, stackTrace) {
      print('ERROR: Erro geral em submitAndAutoCorrect: $e');
      print('ERROR: StackTrace: $stackTrace');
      emit(SubmissionErrorState('Erro ao processar: $e', 'PROCESSING_ERROR'));
    }
  }

  /// Substituir submissão usando quick-function com submission_id
  /// Para quando já existe uma submissão no banco e queremos reprocessar
  Future<void> replaceSubmissionWithQuickFunction({
    required int submissionId,
    required File imageFile,
    required String userId,
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

      // 2. Upload da nova imagem para Storage
      emit(SubmissionUploadingState(25));
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'replace/$submissionId/$timestamp.jpg';

      await _supabase.storage
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
      print(
        'DEBUG: replaceSubmissionWithQuickFunction - Imagem enviada: $imageUrl',
      );

      // 4. Buscar dados da submissão existente
      final submissionData = await _supabase
          .from('submissoes')
          .select('prova_id, aluno_id')
          .eq('id', submissionId)
          .single();

      final provaId = submissionData['prova_id'] as int;
      final alunoId = submissionData['aluno_id'] as int;

      print(
        'DEBUG: replaceSubmissionWithQuickFunction - provaId: $provaId, alunoId: $alunoId',
      );

      emit(SubmissionUploadingState(85));

      // 5. Chamar quick-function com submission_id
      print(
        'DEBUG: replaceSubmissionWithQuickFunction - Chamando quick-function',
      );
      final requestBody = {
        'provaId': provaId,
        'alunoId': alunoId,
        'image_url': imageUrl,
        'userId': userId,
        'submission_id': submissionId.toString(),
      };
      print(
        'DEBUG: replaceSubmissionWithQuickFunction - Request body: $requestBody',
      );

      final functionResponse = await _supabase.functions.invoke(
        'quick-function',
        body: requestBody,
      );

      emit(SubmissionUploadingState(100));

      print(
        'DEBUG: replaceSubmissionWithQuickFunction - Response status: ${functionResponse.status}',
      );
      print(
        'DEBUG: replaceSubmissionWithQuickFunction - Response data: ${functionResponse.data}',
      );

      if (functionResponse.status != 200) {
        throw Exception(
          'Erro na Edge Function: ${functionResponse.status} - ${functionResponse.data}',
        );
      }

      final responseData = functionResponse.data;
      if (responseData['error'] != null) {
        throw Exception(responseData['error']);
      }

      // 6. Processar resultado retornado pela função
      try {
        Map<String, dynamic> submissionResult;
        if (responseData is Map<String, dynamic>) {
          submissionResult = responseData;
        } else if (responseData is Map) {
          submissionResult = Map<String, dynamic>.from(responseData);
        } else {
          throw Exception(
            'Resposta da função não é um objeto válido: ${responseData.runtimeType}',
          );
        }

        final finalSubmission = SubmissionModel.fromJson(submissionResult);
        print(
          'DEBUG: replaceSubmissionWithQuickFunction - Submission parseado com sucesso: ${finalSubmission.id}',
        );

        emit(SubmissionCompletedState(finalSubmission));
      } catch (parseError, stackTrace) {
        print(
          'ERROR: replaceSubmissionWithQuickFunction - Erro ao fazer parse da resposta: $parseError',
        );
        print('ERROR: StackTrace: $stackTrace');
        print('ERROR: ResponseData: $responseData');
        emit(
          SubmissionErrorState(
            'Erro ao processar resultado: $parseError',
            'PARSE_ERROR',
          ),
        );
      }
    } catch (e, stackTrace) {
      print('ERROR: replaceSubmissionWithQuickFunction - Erro geral: $e');
      print('ERROR: StackTrace: $stackTrace');
      emit(
        SubmissionErrorState(
          'Erro ao substituir submissão: $e',
          'REPLACE_ERROR',
        ),
      );
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
  final String step;
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
