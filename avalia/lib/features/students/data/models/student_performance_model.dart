class StudentPerformanceModel {
  final int alunoId;
  final String alunoNome;
  final String matricula;
  final int turmaId;
  final int provasAplicadas;
  final int provasCorrigidas;
  final double mediaAluno;
  final double mediaTurma;
  final bool acimaDaMedia;
  final bool correcaoPendente;

  StudentPerformanceModel({
    required this.alunoId,
    required this.alunoNome,
    required this.matricula,
    required this.turmaId,
    required this.provasAplicadas,
    required this.provasCorrigidas,
    required this.mediaAluno,
    required this.mediaTurma,
    required this.acimaDaMedia,
    required this.correcaoPendente,
  });

  factory StudentPerformanceModel.fromJson(Map<String, dynamic> json) {
    return StudentPerformanceModel(
      alunoId: json['aluno_id'],
      alunoNome: json['aluno_nome'],
      matricula: json['matricula'],
      turmaId: json['turma_id'],
      provasAplicadas: json['provas_aplicadas'] ?? 0,
      provasCorrigidas: json['provas_corrigidas'] ?? 0,
      mediaAluno: (json['media_aluno'] as num).toDouble(),
      mediaTurma: (json['media_turma'] as num).toDouble(),
      acimaDaMedia: json['acima_da_media'] ?? false,
      correcaoPendente: json['correcao_pendente'] ?? false,
    );
  }
}
