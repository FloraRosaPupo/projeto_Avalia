import 'package:bloc/bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/state/base_state.dart';
import '../../data/models/student_performance_model.dart';

class StudentPerformanceCubit extends Cubit<BaseState> {
  StudentPerformanceCubit() : super(InitialState());

  Future<void> getStudentPerformance(int studentId) async {
    emit(LoadingState());
    try {
      final response = await Supabase.instance.client
          .from('v_alunos_desempenho_turma')
          .select()
          .eq('aluno_id', studentId)
          .single();

      final performance = StudentPerformanceModel.fromJson(response);
      emit(SuccessState<StudentPerformanceModel>(performance));
    } catch (e) {
      print('Erro ao buscar desempenho do aluno: $e');
      emit(ErrorState(e.toString()));
    }
  }
}
