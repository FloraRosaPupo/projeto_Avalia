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
}
