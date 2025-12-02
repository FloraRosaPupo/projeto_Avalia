import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/state/base_state.dart';
import '../../data/models/exam_model.dart';

class ExamsCubit extends Cubit<BaseState> {
  ExamsCubit() : super(InitialState());

  Future<void> getExamsByUserId(String userId) async {
    emit(LoadingState());
    try {
      final response = await Supabase.instance.client
          .from('provas')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final exams = (response as List<dynamic>)
          .map((e) => ExamModel.fromJson(e as Map<String, dynamic>))
          .toList();

      emit(SuccessState<List<ExamModel>>(exams));
    } catch (e) {
      print('Erro ao buscar provas: $e');
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
}
