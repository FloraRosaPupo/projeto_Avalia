// auth_cubit.dart
// Cubit responsável pela autenticação (login e registro) usando Supabase.

import 'package:bloc/bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/state/base_state.dart';

class AuthCubit extends Cubit<BaseState> {
  AuthCubit() : super(InitialState());

  /// Faz login com email e senha.
  Future<void> login({required String email, required String password}) async {
    emit(LoadingState());
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.session != null) {
        emit(SuccessState<void>(null)); // sucesso sem payload específico
      } else {
        emit(ErrorState('Falha ao fazer login.'));
      }
    } catch (e) {
      emit(ErrorState(e.toString()));
    }
  }

  /// Registra um novo usuário.
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(LoadingState());
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      if (response.user != null) {
        emit(SuccessState<void>(null));
      } else {
        emit(ErrorState('Falha ao registrar.'));
      }
    } catch (e) {
      emit(ErrorState(e.toString()));
    }
  }

  
}

