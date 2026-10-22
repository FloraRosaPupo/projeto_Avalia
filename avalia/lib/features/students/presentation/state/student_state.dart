part of '../../presentation/cubit/student_cubit.dart';

enum StudentStatus { initial, loading, success, error }

class StudentState extends Equatable {
  const StudentState({
    this.status = StudentStatus.initial,
    this.errorMessage,
    this.student,
  });

  final StudentStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? student;

  @override
  List<Object?> get props => [status, errorMessage, student];

  StudentState copyWith({
    StudentStatus? status,
    String? errorMessage,
    Map<String, dynamic>? student,
  }) {
    return StudentState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      student: student ?? this.student,
    );
  }
}
