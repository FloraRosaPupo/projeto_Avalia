class SubmissionModel {
  final String? id;
  final String provaId;
  final String alunoId;
  final String? imageUrl;
  final SubmissionStatus status;
  final double? nota;
  final int? acertos;
  final int? totalQuestoes;
  final List<QuestionDetail>? detalhamento;
  final List<SubmissionIssue>? issues;
  final double? confidence;
  final DateTime? uploadedAt;
  final DateTime? finishedAt;
  final int attemptNumber;

  SubmissionModel({
    this.id,
    required this.provaId,
    required this.alunoId,
    this.imageUrl,
    this.status = SubmissionStatus.pending,
    this.nota,
    this.acertos,
    this.totalQuestoes,
    this.detalhamento,
    this.issues,
    this.confidence,
    this.uploadedAt,
    this.finishedAt,
    this.attemptNumber = 1,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    return SubmissionModel(
      id: json['id'] as String?,
      provaId: json['prova_id'] as String,
      alunoId: json['aluno_id'] as String,
      imageUrl: json['image_url'] as String?,
      status: SubmissionStatus.fromString(
        json['status'] as String? ?? 'pending',
      ),
      nota: json['nota'] != null ? (json['nota'] as num).toDouble() : null,
      acertos: json['acertos'] as int?,
      totalQuestoes: json['total_questoes'] as int?,
      detalhamento: json['detalhamento'] != null
          ? (json['detalhamento'] as List)
                .map((e) => QuestionDetail.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      issues: json['issues'] != null
          ? (json['issues'] as List)
                .map((e) => SubmissionIssue.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
      confidence: json['confidence'] != null
          ? (json['confidence'] as num).toDouble()
          : null,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'] as String)
          : null,
      finishedAt: json['finished_at'] != null
          ? DateTime.parse(json['finished_at'] as String)
          : null,
      attemptNumber: json['attempt_number'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prova_id': provaId,
      'aluno_id': alunoId,
      'image_url': imageUrl,
      'status': status.value,
      'nota': nota,
      'acertos': acertos,
      'total_questoes': totalQuestoes,
      'detalhamento': detalhamento?.map((e) => e.toJson()).toList(),
      'issues': issues?.map((e) => e.toJson()).toList(),
      'confidence': confidence,
      'uploaded_at': uploadedAt?.toIso8601String(),
      'finished_at': finishedAt?.toIso8601String(),
      'attempt_number': attemptNumber,
    };
  }

  SubmissionModel copyWith({
    String? id,
    String? provaId,
    String? alunoId,
    String? imageUrl,
    SubmissionStatus? status,
    double? nota,
    int? acertos,
    int? totalQuestoes,
    List<QuestionDetail>? detalhamento,
    List<SubmissionIssue>? issues,
    double? confidence,
    DateTime? uploadedAt,
    DateTime? finishedAt,
    int? attemptNumber,
  }) {
    return SubmissionModel(
      id: id ?? this.id,
      provaId: provaId ?? this.provaId,
      alunoId: alunoId ?? this.alunoId,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      nota: nota ?? this.nota,
      acertos: acertos ?? this.acertos,
      totalQuestoes: totalQuestoes ?? this.totalQuestoes,
      detalhamento: detalhamento ?? this.detalhamento,
      issues: issues ?? this.issues,
      confidence: confidence ?? this.confidence,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      attemptNumber: attemptNumber ?? this.attemptNumber,
    );
  }
}

enum SubmissionStatus {
  pending('pending'),
  processingUpload('processing_upload'),
  processingAnalysis('processing_analysis'),
  aiValidation('ai_validation'),
  reviewNeeded('review_needed'),
  graded('graded'),
  error('error');

  final String value;
  const SubmissionStatus(this.value);

  static SubmissionStatus fromString(String value) {
    return SubmissionStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SubmissionStatus.pending,
    );
  }
}

class QuestionDetail {
  final int questionNumber;
  final String? studentAnswer;
  final String officialAnswer;
  final bool isCorrect;
  final double? confidence;

  QuestionDetail({
    required this.questionNumber,
    this.studentAnswer,
    required this.officialAnswer,
    required this.isCorrect,
    this.confidence,
  });

  factory QuestionDetail.fromJson(Map<String, dynamic> json) {
    return QuestionDetail(
      questionNumber: json['question_number'] as int,
      studentAnswer: json['student_answer'] as String?,
      officialAnswer: json['official_answer'] as String,
      isCorrect: json['is_correct'] as bool,
      confidence: json['confidence'] != null
          ? (json['confidence'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_number': questionNumber,
      'student_answer': studentAnswer,
      'official_answer': officialAnswer,
      'is_correct': isCorrect,
      'confidence': confidence,
    };
  }
}

class SubmissionIssue {
  final String type;
  final String message;
  final String severity; // 'warning', 'error', 'critical'
  final List<int>? affectedQuestions;

  SubmissionIssue({
    required this.type,
    required this.message,
    required this.severity,
    this.affectedQuestions,
  });

  factory SubmissionIssue.fromJson(Map<String, dynamic> json) {
    return SubmissionIssue(
      type: json['type'] as String,
      message: json['message'] as String,
      severity: json['severity'] as String,
      affectedQuestions: json['affected_questions'] != null
          ? List<int>.from(json['affected_questions'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'message': message,
      'severity': severity,
      'affected_questions': affectedQuestions,
    };
  }
}
