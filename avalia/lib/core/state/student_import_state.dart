part of '../../presentation/cubit/student_import_cubit.dart';

/// Estado específico para sucesso na importação de alunos.
///
/// Contém informações sobre quantos alunos foram importados.
class StudentImportSuccessState extends BaseState {
  final int totalImported;
  final int totalRows;

  const StudentImportSuccessState({
    required this.totalImported,
    required this.totalRows,
  });

  @override
  List<Object?> get props => [totalImported, totalRows];
}
