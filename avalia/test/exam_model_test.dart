import 'package:flutter_test/flutter_test.dart';
import 'package:avalia/features/exams/data/models/exam_model.dart';
void main() {
  test('prova preserva campos após conversão JSON', () {
    final exam=ExamModel(id:1,createdAt:DateTime.utc(2026,10,21),turmasId:[2,3],status:'ABERTA');
    final restored=ExamModel.fromJson(exam.toJson());
    expect(restored.turmasId,[2,3]);
    expect(restored.createdAt,exam.createdAt);
    expect(restored.statusFormatted,'Aberta');
  });
  test('status ausente é apresentado vazio', () {
    expect(ExamModel(id:1,createdAt:DateTime.utc(2026),turmasId:[]).statusFormatted,'');
  });
}
