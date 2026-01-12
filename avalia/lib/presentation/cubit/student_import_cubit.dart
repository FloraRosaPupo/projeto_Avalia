import 'package:bloc/bloc.dart';
import '../../core/state/base_state.dart';

part '../../core/state/student_import_state.dart';

class StudentImportCubit extends Cubit<BaseState> {
  StudentImportCubit() : super(InitialState());

  // TODO: Implementar lógica de importação de alunos
}
