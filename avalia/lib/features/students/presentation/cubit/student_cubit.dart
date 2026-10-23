import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'package:avalia/features/students/presentation/state/student_state.dart';

class StudentCubit extends Cubit<StudentState> {
  final SupabaseClient _client;
  StudentCubit({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client,
      super(const StudentState());

  Future<void> createStudent({
    required int turmaId,
    required String nome,
    String? matricula,
  }) async {
    emit(const StudentState(status: StudentStatus.loading));

    try {
      final supabase = _client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        emit(
          const StudentState(
            status: StudentStatus.error,
            errorMessage: 'Usuário não autenticado',
          ),
        );
        return;
      }

      final response = await supabase.from('alunos').insert({
        'turma_id': turmaId,
        'nome': nome,
        'matricula': matricula,
        'user_id': user.id,
      }).select();

      if (response.isEmpty) {
        emit(
          const StudentState(
            status: StudentStatus.error,
            errorMessage: 'Erro ao criar aluno',
          ),
        );
      } else {
        emit(
          StudentState(status: StudentStatus.success, student: response.first),
        );
      }
    } catch (e) {
      emit(
        StudentState(status: StudentStatus.error, errorMessage: e.toString()),
      );
    }
  }

  void reset() {
    emit(const StudentState());
  }
}
