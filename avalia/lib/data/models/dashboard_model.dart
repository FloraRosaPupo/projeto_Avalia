import 'dart:convert';

/// Root object returned by the RPC.
class DashboardResponse {
  final String userId;
  final int provaCount;
  final int turmaCount;
  final List<Activity> recentActivities;

  DashboardResponse({
    required this.userId,
    required this.provaCount,
    required this.turmaCount,
    required this.recentActivities,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      userId: json['user_id'] as String,
      provaCount: json['prova_count'] as int,
      turmaCount: json['turma_count'] as int,
      recentActivities: (json['recent_activities'] as List<dynamic>)
          .map((e) => Activity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'prova_count': provaCount,
    'turma_count': turmaCount,
    'recent_activities': recentActivities
        .map((activity) => activity.toJson())
        .toList(),
  };
}

/// Individual activity entry.
class Activity {
  final String? id;
  final Meta? meta;
  final String? type;
  final String? title;
  final String action;
  final String resource;
  final DateTime? createdAt;
  final String? description;

  Activity({
    this.id,
    this.meta,
    this.type,
    this.title,
    this.action = '',
    this.resource = '',
    this.createdAt,
    this.description,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String?,
      meta: json['meta'] != null
          ? Meta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
      type: json['type'] as String?,
      title: json['title'] as String?,
      action: json['action'] as String? ?? '',
      resource: json['resource'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'meta': meta?.toJson(),
    'type': type,
    'title': title,
    'action': action,
    'resource': resource,
    'created_at': createdAt?.toUtc().toIso8601String(),
    'description': description,
  };
}

/// The `meta` sub‑object inside an activity.
class Meta {
  final String? id;
  final String? nome;
  final DateTime? criadoEm;

  Meta({this.id, this.nome, this.criadoEm});

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      id: json['id'] as String?,
      nome: json['nome'] as String?,
      criadoEm: json['criado_em'] != null
          ? DateTime.parse(json['criado_em'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'criado_em': criadoEm?.toUtc().toIso8601String(),
  };
}
