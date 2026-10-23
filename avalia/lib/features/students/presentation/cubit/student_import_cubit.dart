import 'package:bloc/bloc.dart';
import 'package:avalia/core/state/base_state.dart';

part 'package:avalia/features/students/presentation/state/student_import_state.dart';

class StudentImportCubit extends Cubit<BaseState> {
  StudentImportCubit() : super(InitialState());

  // TODO: Implementar lógica de importação de alunos
}
