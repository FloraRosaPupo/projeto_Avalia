class ClassDetailModel {
  final Turma turma;
  final List<Aluno> alunos;
  final List<Prova> provas;
  final int numeroAlunos;

  ClassDetailModel({
    required this.turma,
    required this.alunos,
    required this.provas,
    required this.numeroAlunos,
  });

  factory ClassDetailModel.fromJson(Map<String, dynamic> json) {
    return ClassDetailModel(
      turma: Turma.fromJson(json['turma']),
      alunos: (json['alunos'] as List).map((i) => Aluno.fromJson(i)).toList(),
      provas: (json['provas'] as List).map((i) => Prova.fromJson(i)).toList(),
      numeroAlunos: json['numero_alunos'],
    );
  }
}

class Turma {
  final int id;
  final String nome;
  final String userId;
  final String criadoEm;
  final String descricao;

  Turma({
    required this.id,
    required this.nome,
    required this.userId,
    required this.criadoEm,
    required this.descricao,
  });

  factory Turma.fromJson(Map<String, dynamic> json) {
    return Turma(
      id: json['id'],
      nome: json['nome'],
      userId: json['user_id'],
      criadoEm: json['criado_em'],
      descricao: json['descricao'] ?? '',
    );
  }
}

class Aluno {
  final int id;
  final String nome;
  final double media;
  final String matricula;
  final bool correcaoPendente;

  Aluno({
    required this.id,
    required this.nome,
    required this.media,
    required this.matricula,
    required this.correcaoPendente,
  });

  factory Aluno.fromJson(Map<String, dynamic> json) {
    return Aluno(
      id: json['id'],
      nome: json['nome'],
      media: (json['media'] as num).toDouble(),
      matricula: json['matricula'],
      correcaoPendente: json['correcao_pendente'],
    );
  }
}

class Prova {
  final int id;
  final String cor;
  final String nome;
  final String status;
  final bool concluida;
  final String urlProva;
  final String createdAt;
  final int numeroSubmissoes;

  Prova({
    required this.id,
    required this.cor,
    required this.nome,
    required this.status,
    required this.concluida,
    required this.urlProva,
    required this.createdAt,
    required this.numeroSubmissoes,
  });

  factory Prova.fromJson(Map<String, dynamic> json) {
    return Prova(
      id: json['id'],
      cor: json['cor'],
      nome: json['nome'],
      status: json['status'],
      concluida: json['concluida'],
      urlProva: json['url_prova'],
      createdAt: json['created_at'],
      numeroSubmissoes: json['numero_submissoes'],
    );
  }
}
