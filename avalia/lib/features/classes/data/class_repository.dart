import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/class_model.dart';
import 'models/class_detail_model.dart';

abstract class ClassRepository {
  Future<ClassListResponse> list(String userId);
  Future<void> create({
    required String userId,
    required String nome,
    String? descricao,
  });
  Future<void> update({
    required int classId,
    required String userId,
    required String nome,
    String? descricao,
  });
  Future<ClassDetailModel> details(int classId);
}

class SupabaseClassRepository implements ClassRepository {
  final SupabaseClient? _client;
  SupabaseClassRepository({SupabaseClient? client}) : _client = client;
  SupabaseClient get client => _client ?? Supabase.instance.client;
  @override
  Future<ClassListResponse> list(String userId) async {
    final rows = await client
        .from('v_turmas_com_numero_alunos')
        .select('*')
        .eq('user_id', userId)
        .order('criado_em', ascending: false);
    return ClassListResponse.fromJson(rows);
  }

  @override
  Future<void> create({
    required String userId,
    required String nome,
    String? descricao,
  }) async {
    await client.from('turmas').insert({
      'user_id': userId,
      'nome': nome,
      'descricao': descricao,
    });
  }

  @override
  Future<void> update({
    required int classId,
    required String userId,
    required String nome,
    String? descricao,
  }) async {
    await client
        .from('turmas')
        .update({'nome': nome, 'descricao': descricao})
        .eq('id', classId)
        .eq('user_id', userId);
  }

  @override
  Future<ClassDetailModel> details(int classId) async {
    final response = await client.rpc(
      'get_turma_com_alunos',
      params: {'p_turma_id': classId},
    );
    return ClassDetailModel.fromJson(response);
  }
}
