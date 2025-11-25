/// Modelo que representa a tabela 'turmas' no Supabase.
class Turma {
  final int id;
  final String? professorId;
  final String nome;
  final DateTime? criadoEm;

  Turma({
    required this.id,
    this.professorId,
    required this.nome,
    this.criadoEm,
  });

  /// Cria uma instância de Turma a partir de um JSON.
  factory Turma.fromJson(Map<String, dynamic> json) {
    return Turma(
      id: json['id'] as int,
      professorId: json['professor_id'] as String?,
      nome: json['nome'] as String,
      criadoEm: json['criado_em'] != null
          ? DateTime.parse(json['criado_em'] as String)
          : null,
    );
  }

  /// Converte a instância de Turma para JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'professor_id': professorId,
      'nome': nome,
      'criado_em': criadoEm?.toIso8601String(),
    };
  }
}
