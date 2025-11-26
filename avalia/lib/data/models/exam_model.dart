class ExamModel {
  final int id;
  final DateTime createdAt;
  final List<int> turmasId;
  final String? urlProva;
  final String? userId;
  final String? status;
  final String? cor;
  final String? nome;

  ExamModel({
    required this.id,
    required this.createdAt,
    required this.turmasId,
    this.urlProva,
    this.userId,
    this.status,
    this.cor,
    this.nome,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      turmasId: (json['turmas_id'] as List<dynamic>)
          .map((e) => e as int)
          .toList(),
      urlProva: json['url_prova'] as String?,
      userId: json['user_id'] as String?,
      status: json['status'] as String?,
      cor: json['cor'] as String?,
      nome: json['nome'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'created_at': createdAt.toIso8601String(),
    'turmas_id': turmasId,
    'url_prova': urlProva,
    'user_id': userId,
    'status': status,
    'cor': cor,
    'nome': nome,
  };
}
