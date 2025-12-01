import 'package:bloc/bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/state/base_state.dart';
import '../../data/models/class_model.dart';
import '../../data/models/class_detail_model.dart';

/// Cubit responsável por gerenciar as turmas do usuário autenticado.
class ClassCubit extends Cubit<BaseState> {
  ClassCubit() : super(InitialState());

  /// Busca todas as turmas do usuário autenticado.
  ///
  /// Filtra as turmas pela coluna `user_id` para retornar apenas
  /// as turmas pertencentes ao usuário logado.
  Future<void> getClassesByUserId({required String userId}) async {
    emit(LoadingState());
    try {
      final response = await Supabase.instance.client
          .from('v_turmas_com_numero_alunos')
          .select('*')
          .eq('user_id', userId)
          .order('criado_em', ascending: false);

      final classList = ClassListResponse.fromJson(response as List<dynamic>);
      emit(SuccessState<ClassListResponse>(classList));
    } catch (e) {
      print('Erro no ClassCubit: $e');
      emit(ErrorState(e.toString()));
    }
  }

  /// Cria uma nova turma para o usuário autenticado.
  Future<void> createClass({
    required String userId,
    required String nome,
    String? descricao,
  }) async {
    emit(LoadingState());
    try {
      await Supabase.instance.client.from('turmas').insert({
        'user_id': userId,
        'nome': nome,
        'descricao': descricao,
      });

      // Recarrega a lista de turmas após criar
      await getClassesByUserId(userId: userId);
    } catch (e) {
      print('Erro ao criar turma: $e');
      emit(ErrorState(e.toString()));
    }
  }

  /// Atualiza uma turma existente.
  Future<void> updateClass({
    required int classId,
    required String userId,
    required String nome,
    String? descricao,
  }) async {
    emit(LoadingState());
    try {
      await Supabase.instance.client
          .from('turmas')
          .update({'nome': nome, 'descricao': descricao})
          .eq('id', classId);

      // Recarrega a lista de turmas após atualizar
      await getClassesByUserId(userId: userId);
    } catch (e) {
      print('Erro ao atualizar turma: $e');
      emit(ErrorState(e.toString()));
    }
  }

  /// Busca os detalhes de uma turma (alunos, provas, etc.) via RPC.
  Future<void> getClassDetails({required int classId}) async {
    emit(LoadingState());
    try {
      final response = await Supabase.instance.client.rpc(
        'get_turma_com_alunos',
        params: {'p_turma_id': classId},
      );

      final classDetail = ClassDetailModel.fromJson(response);
      emit(SuccessState<ClassDetailModel>(classDetail));
    } catch (e) {
      print('Erro ao buscar detalhes da turma: $e');
      emit(ErrorState(e.toString()));
    }
  }
}
