import 'package:bloc/bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/state/base_state.dart';
import '../../data/models/student_exam_model.dart';

class StudentExamsCubit extends Cubit<BaseState> {
  StudentExamsCubit() : super(InitialState());

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
}
