import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/state/base_state.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/student_exam_model.dart';

class ExamsCubit extends Cubit<BaseState> {
  ExamsCubit() : super(InitialState());

  Future<void> getStudentByUserID(String userId) async {
    emit(LoadingState());
    try {
      print('Fetching exams for studentId: $userId');
      final response = await Supabase.instance.client.rpc(
        'get_provas_por_user',
        params: {'p_user_id': userId},
      );

      print('Raw response from get_provas_por_user: $response');

      List<dynamic> data = [];

      if (response is Map && response.containsKey('provas')) {
        data = response['provas'] as List<dynamic>;
      } else if (response is List) {
        data = response;
      } else if (response is Map) {
        // Fallback for single item or unexpected structure, though likely not needed if API is consistent
        data = [response];
      }

      final exams = data
          .map((e) => StudentExamModel.fromJson(e as Map<String, dynamic>))
          .toList();

      print('Parsed exams count: ${exams.length}');
      emit(SuccessState<List<StudentExamModel>>(exams));
    } catch (e) {
      print('Erro ao buscar provas do aluno: $e');
      emit(ErrorState(e.toString()));
    }
  }

  Future<String?> uploadGabarito(File imageFile) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');

      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Supabase.instance.client.storage
          .from('gabaritos')
          .upload(fileName, imageFile);

      final url = Supabase.instance.client.storage
          .from('gabaritos')
          .getPublicUrl(fileName);

      return url;
    } catch (e) {
      print('Erro ao fazer upload do gabarito: $e');
      throw Exception('Erro ao fazer upload do gabarito');
    }
  }

  /// Remove um gabarito do Storage do Supabase
  /// Extrai o nome do arquivo da URL e remove do bucket 'gabaritos'
  Future<void> deleteGabarito(String gabaritoUrl) async {
    try {
      // Extrair nome do arquivo da URL
      // URL formato: https://.../storage/v1/object/public/gabaritos/FILENAME
      final uri = Uri.parse(gabaritoUrl);
      final pathSegments = uri.pathSegments;

      // Encontrar o índice de 'gabaritos' e pegar o próximo segmento
      final gabaritosIndex = pathSegments.indexOf('gabaritos');
      if (gabaritosIndex == -1 || gabaritosIndex >= pathSegments.length - 1) {
        throw Exception('URL inválida: não foi possível extrair nome do arquivo');
      }

      final fileName = pathSegments[gabaritosIndex + 1];

      print('Deletando gabarito: $fileName');

      await Supabase.instance.client.storage
          .from('gabaritos')
          .remove([fileName]);

      print('Gabarito deletado com sucesso: $fileName');
    } catch (e) {
      print('Erro ao deletar gabarito: $e');
      // Não lançar exceção para não bloquear o fluxo se o arquivo já foi deletado
      // ou não existe mais
    }
  }

  Future<void> createExam(Map<String, dynamic> examData) async {
    emit(LoadingState());
    try {
      final response = await Supabase.instance.client
          .from('provas')
          .insert(examData)
          .select()
          .single();

      final newExam = ExamModel.fromJson(response);

      // Se tivermos uma lista atual, adicionamos o novo exame
      if (state is SuccessState<List<ExamModel>>) {
        final currentList = (state as SuccessState<List<ExamModel>>).data;
        emit(SuccessState<List<ExamModel>>([newExam, ...currentList]));
      } else {
        // Se não, buscamos tudo de novo ou apenas emitimos sucesso
        // Para simplificar, vamos emitir sucesso com a lista contendo apenas o novo
        // Idealmente deveríamos buscar a lista atualizada
        emit(SuccessState<List<ExamModel>>([newExam]));
      }
    } catch (e) {
      print('Erro ao criar prova: $e');
      emit(ErrorState(e.toString()));
      rethrow;
    }
  }

  Future<void> updateExam(int examId, Map<String, dynamic> examData) async {
    emit(LoadingState());
    try {
      final response = await Supabase.instance.client
          .from('provas')
          .update(examData)
          .eq('id', examId)
          .select()
          .single();

      final updatedExam = ExamModel.fromJson(response);

      if (state is SuccessState<List<ExamModel>>) {
        final currentList = (state as SuccessState<List<ExamModel>>).data;
        final updatedList = currentList.map((exam) {
          return exam.id == examId ? updatedExam : exam;
        }).toList();
        emit(SuccessState<List<ExamModel>>(updatedList));
      } else {
        emit(SuccessState<List<ExamModel>>([updatedExam]));
      }
    } catch (e) {
      print('Erro ao atualizar prova: $e');
      emit(ErrorState(e.toString()));
      rethrow;
    }
  }

  Future<void> getStudentExams(int studentId) async {
    emit(LoadingState());
    try {
      print('Fetching exams for studentId: $studentId');
      final response = await Supabase.instance.client.rpc(
        'get_provas_do_aluno',
        params: {'p_aluno_id': studentId},
      );

      print('Raw response from get_provas_do_aluno: $response');

      List<dynamic> data = [];

      if (response is Map && response.containsKey('provas')) {
        data = response['provas'] as List<dynamic>;
      } else if (response is List) {
        data = response;
      } else if (response is Map) {
        // Fallback for single item or unexpected structure, though likely not needed if API is consistent
        data = [response];
      }

      final exams = data
          .map((e) => StudentExamModel.fromJson(e as Map<String, dynamic>))
          .toList();

      print('Parsed exams count: ${exams.length}');
      emit(SuccessState<List<StudentExamModel>>(exams));
    } catch (e) {
      print('Erro ao buscar provas do aluno: $e');
      emit(ErrorState(e.toString()));
    }
  }

  /// Busca uma prova completa pelo ID, incluindo turmas vinculadas
  Future<void> getExamById(int examId) async {
    emit(LoadingState());
    try {
      print('🔍 Buscando prova completa pelo ID: $examId');
      
      final response = await Supabase.instance.client
          .from('provas')
          .select()
          .eq('id', examId)
          .maybeSingle();

      if (response == null) {
        print('❌ Prova não encontrada com ID: $examId');
        emit(ErrorState('Prova não encontrada'));
        return;
      }

      print('✅ Dados da prova recebidos do banco:');
      print('   - ID: ${response['id']}');
      print('   - Nome: ${response['nome']}');
      print('   - URL Prova: ${response['url_prova']}');
      print('   - Turmas ID (raw): ${response['turmas_id']}');
      print('   - Tipo de turmas_id: ${response['turmas_id'].runtimeType}');

      final exam = ExamModel.fromJson(response);
      
      print('✅ ExamModel criado:');
      print('   - Turmas ID: ${exam.turmasId}');
      print('   - Quantidade de turmas: ${exam.turmasId.length}');

      emit(SuccessState<ExamModel>(exam));
    } catch (e, stackTrace) {
      print('❌ Erro ao buscar prova pelo ID: $e');
      print('Stack trace: $stackTrace');
      emit(ErrorState('Erro ao buscar prova: $e'));
    }
  }
}
