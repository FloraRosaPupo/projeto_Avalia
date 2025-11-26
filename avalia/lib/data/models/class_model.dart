/// Model for Class (Turma) entity
class ClassModel {
  final int id;
  final String nome;
  final String? descricao;
  final String userId;
  final DateTime criadoEm;
  final DateTime? atualizadoEm;
  final int? numeroAlunos;

  ClassModel({
    required this.id,
    required this.nome,
    this.descricao,
    required this.userId,
    required this.criadoEm,
    this.atualizadoEm,
    this.numeroAlunos,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as int,
      nome: json['nome'] as String,
      descricao: json['descricao'] as String?,
      userId: json['user_id'] as String,
      criadoEm: DateTime.parse(json['criado_em'] as String),
      atualizadoEm: json['atualizado_em'] != null
          ? DateTime.parse(json['atualizado_em'] as String)
          : null,
      numeroAlunos: json['numero_alunos'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'descricao': descricao,
    'user_id': userId,
    'criado_em': criadoEm.toUtc().toIso8601String(),
    'atualizado_em': atualizadoEm?.toUtc().toIso8601String(),
    'numero_alunos': numeroAlunos,
  };
}

/// Response wrapper for list of classes
class ClassListResponse {
  final List<ClassModel> classes;

  ClassListResponse({required this.classes});

  factory ClassListResponse.fromJson(List<dynamic> json) {
    return ClassListResponse(
      classes: json
          .map((e) => ClassModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
