class StudentExamModel {
  final int provaId;
  final String nome;
  final DateTime? data;
  final String status;
  final double? nota;
  final String? cor;

  StudentExamModel({
    required this.provaId,
    required this.nome,
    this.data,
    required this.status,
    this.nota,
    this.cor,
  });

  factory StudentExamModel.fromJson(Map<String, dynamic> json) {
    return StudentExamModel(
      provaId: json['prova_id'] ?? json['id'] ?? 0,
      nome: json['nome'] ?? 'Sem nome',
      data: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      status: json['status'] ?? 'Pendente',
      nota: json['nota'] != null ? (json['nota'] as num).toDouble() : null,
      cor: json['cor'],
    );
  }
}
