import 'package:bloc/bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/state/base_state.dart';
import '../../data/models/dashboard_model.dart';

/// Cubit responsável por chamar a função RPC do Supabase.
///
/// Substitua `your_rpc_function` pelo nome da sua função RPC e ajuste os
/// parâmetros conforme necessário.
class DashboardCubit extends Cubit<BaseState> {
  DashboardCubit() : super(InitialState());

  /// Chama a RPC `public.get_recent_activities_json`.
  ///
  /// `userId` – UUID do usuário logado.
  /// `limit` – número máximo de atividades a retornar (default 10).
  Future<void> getRecentActivities({
    required String userId,
    int limit = 10,
  }) async {
    emit(LoadingState());
    try {
      final response = await Supabase.instance.client.rpc(
        'get_recent_activities_json',
        params: {'p_user': userId, 'p_limit': limit},
      );
      // A resposta é um jsonb; pode ser usado como payload se necessário.

      final dashboardData = DashboardResponse.fromJson(
        response as Map<String, dynamic>,
      );
      emit(SuccessState<DashboardResponse>(dashboardData));
    } catch (e) {
      print('Erro no DashboardCubit: $e');
      emit(ErrorState(e.toString()));
    }
  }
}
