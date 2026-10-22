import 'dart:convert';

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
    this.finishedAt,
    this.attemptNumber = 1,
  });

  static List<QuestionDetail>? _parseRespostasToDetalhamento(
    dynamic respostas,
  ) {
    if (respostas == null) return null;

    dynamic decoded = respostas;
    if (decoded is String) {
      decoded = jsonDecode(decoded);
    }

    if (decoded is! List) return null;

    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map(QuestionDetail.fromRespostasJson)
        .toList();
  }

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    try {
      // Função auxiliar para converter para String de forma segura
      String? _safeString(dynamic value) {
        if (value == null) return null;
        if (value is String) return value;
        return value.toString();
      }

      // Função auxiliar para converter para int de forma segura
      int? _safeInt(dynamic value) {
        if (value == null) return null;
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value is String) return int.tryParse(value);
        return null;
      }

      // Função auxiliar para converter DateTime de forma segura
      DateTime? _safeDateTime(dynamic value) {
        if (value == null) return null;
        if (value is DateTime) return value;
        if (value is String) {
          try {
            return DateTime.parse(value);
          } catch (e) {
            print('ERROR: Erro ao fazer parse de data: $value - $e');
            return null;
          }
        }
        return null;
      }

      return SubmissionModel(
        id: _safeString(json['id']),
        provaId: _safeString(json['prova_id']) ?? '',
        alunoId: _safeString(json['aluno_id']) ?? '',
        imageUrl: _safeString(json['image_url']),
        status: SubmissionStatus.fromString(
          _safeString(json['status']) ?? 'pending',
        ),
        nota: json['nota'] != null ? (json['nota'] as num).toDouble() : null,
        acertos: _safeInt(json['acertos']),
        totalQuestoes: _safeInt(json['total_questoes']),
        detalhamento: json['detalhamento'] != null
            ? (json['detalhamento'] is List
                  ? (json['detalhamento'] as List)
                        .map((e) {
                          try {
                            if (e is Map<String, dynamic>) {
                              return QuestionDetail.fromJson(e);
                            } else if (e is Map) {
                              return QuestionDetail.fromJson(
                                Map<String, dynamic>.from(e),
                              );
                            }
                            return null;
                          } catch (e) {
                            print(
                              'ERROR: Erro ao fazer parse de detalhamento: $e',
                            );
                            return null;
                          }
                        })
                        .whereType<QuestionDetail>()
                        .toList()
                  : null)
            : _parseRespostasToDetalhamento(json['respostas']),
        issues: json['issues'] != null && json['issues'] is List
            ? (json['issues'] as List)
                  .map((e) {
                    try {
                      if (e is Map<String, dynamic>) {
                        return SubmissionIssue.fromJson(e);
                      } else if (e is Map) {
                        return SubmissionIssue.fromJson(
                          Map<String, dynamic>.from(e),
                        );
                      }
                      return null;
                    } catch (e) {
                      print('ERROR: Erro ao fazer parse de issue: $e');
                      return null;
                    }
                  })
                  .whereType<SubmissionIssue>()
                  .toList()
            : null,
        confidence: json['confidence'] != null
            ? (json['confidence'] as num).toDouble()
            : null,
        finishedAt: _safeDateTime(json['finished_at']),
        attemptNumber: _safeInt(json['attempt_number']) ?? 1,
      );
    } catch (e, stackTrace) {
      print('ERROR: Erro ao fazer parse de SubmissionModel: $e');
      print('ERROR: StackTrace: $stackTrace');
      print('ERROR: JSON recebido: $json');
      rethrow;
    }
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
      'issues': issues?.map((e) => e.toJson()).toList(),
      'confidence': confidence,
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
  graded('Concluida'),
  error('error');

  final String value;
  const SubmissionStatus(this.value);

  static SubmissionStatus fromString(String value) {
    return SubmissionStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SubmissionStatus.pending,
    );
  }

  String get formatted {
    switch (this) {
      case SubmissionStatus.pending:
        return 'Pendente';
      case SubmissionStatus.processingUpload:
        return 'Processando Upload';
      case SubmissionStatus.processingAnalysis:
        return 'Processando Análise';
      case SubmissionStatus.aiValidation:
        return 'Validação IA';
      case SubmissionStatus.reviewNeeded:
        return 'Revisão Necessária';
      case SubmissionStatus.graded:
        return 'Concluída';
      case SubmissionStatus.error:
        return 'Erro';
    }
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
    try {
      // Função auxiliar para converter para int de forma segura
      int _safeInt(dynamic value) {
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value is String) return int.tryParse(value) ?? 0;
        return 0;
      }

      // Função auxiliar para converter para String de forma segura
      String? _safeString(dynamic value) {
        if (value == null) return null;
        if (value is String) return value.isEmpty ? null : value;
        return value.toString();
      }

      // Função auxiliar para converter para bool de forma segura
      bool _safeBool(dynamic value) {
        if (value is bool) return value;
        if (value is String) {
          return value.toLowerCase() == 'true' || value == '1';
        }
        if (value is num) return value != 0;
        return false;
      }

      return QuestionDetail(
        questionNumber: _safeInt(json['question_number']),
        studentAnswer: _safeString(json['student_answer']),
        officialAnswer: _safeString(json['official_answer']) ?? '',
        isCorrect: _safeBool(json['is_correct']),
        confidence: json['confidence'] != null
            ? (json['confidence'] as num).toDouble()
            : null,
      );
    } catch (e, stackTrace) {
      print('ERROR: Erro ao fazer parse de QuestionDetail: $e');
      print('ERROR: StackTrace: $stackTrace');
      print('ERROR: JSON recebido: $json');
      rethrow;
    }
  }

  factory QuestionDetail.fromRespostasJson(Map<String, dynamic> json) {
    return QuestionDetail(
      questionNumber: (json['questao'] as num).toInt(),
      studentAnswer: json['resposta_aluno']?.toString(),
      officialAnswer: json['resposta_correta']?.toString() ?? '',
      isCorrect: json['correta'] == true,
      confidence: null,
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
    try {
      // Função auxiliar para converter para String de forma segura
      String _safeString(dynamic value, String defaultValue) {
        if (value == null) return defaultValue;
        if (value is String) return value;
        return value.toString();
      }

      // Função auxiliar para converter List<int> de forma segura
      List<int>? _safeIntList(dynamic value) {
        if (value == null) return null;
        if (value is List) {
          return value
              .map((e) {
                if (e is int) return e;
                if (e is num) return e.toInt();
                if (e is String) return int.tryParse(e);
                return null;
              })
              .whereType<int>()
              .toList();
        }
        return null;
      }

      return SubmissionIssue(
        type: _safeString(json['type'], 'unknown'),
        message: _safeString(json['message'], ''),
        severity: _safeString(json['severity'], 'warning'),
        affectedQuestions: _safeIntList(json['affected_questions']),
      );
    } catch (e, stackTrace) {
      print('ERROR: Erro ao fazer parse de SubmissionIssue: $e');
      print('ERROR: StackTrace: $stackTrace');
      print('ERROR: JSON recebido: $json');
      rethrow;
    }
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
