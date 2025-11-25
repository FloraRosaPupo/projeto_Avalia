import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/state/base_state.dart';
import '../../data/models/turma_model.dart';

/// Cubit responsável por gerenciar o estado da listagem de turmas.
class TurmasCubit extends Cubit<BaseState> {
  TurmasCubit() : super(InitialState());

  /// Busca as turmas na tabela 'turmas' do Supabase.
  Future<void> fetchTurmas() async {
    // Emite estado de carregamento
    emit(LoadingState());

    try {
      // Realiza a consulta no Supabase
      final response = await Supabase.instance.client
          .from('turmas')
          .select()
          .order('criado_em', ascending: false);

      // Converte a resposta para uma lista de objetos Turma
      final turmas = (response as List)
          .map((item) => Turma.fromJson(item))
          .toList();

      // Emite estado de sucesso com os dados
      emit(SuccessState<List<Turma>>(turmas));
    } catch (e) {
      // Emite estado de erro em caso de falha
      emit(ErrorState(e.toString()));
    }
  }
}
