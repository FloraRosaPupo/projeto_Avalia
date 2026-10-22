// auth_cubit.dart
// Cubit responsável pela autenticação (login e registro) usando Supabase.

import 'package:bloc/bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:avalia/core/state/base_state.dart';
import 'package:avalia/features/auth/data/auth_service.dart';

class AuthCubit extends Cubit<BaseState> {
  final IAuthService _authService;

  AuthCubit({IAuthService? authService})
      : _authService = authService ?? SupabaseAuthService(),
        super(InitialState());

  /// Faz login com email e senha.
  Future<void> login({required String email, required String password}) async {
    emit(LoadingState());
    try {
      final response = await _authService.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.session != null && response.user != null) {
        emit(SuccessState<User>(response.user!));
      } else {
        emit(const ErrorState('Falha ao fazer login. Sessão não foi criada.'));
      }
    } on AuthException catch (e) {
      emit(ErrorState(_translateAuthError(e.message)));
    } catch (e) {
      emit(const ErrorState('Erro de conexão. Verifique sua internet.'));
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
      final response = await _authService.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      if (response.user != null) {
        emit(SuccessState<User>(response.user!));
      } else {
        emit(const ErrorState('Falha ao registrar usuário.'));
      }
    } on AuthException catch (e) {
      emit(ErrorState(_translateAuthError(e.message)));
    } catch (e) {
      emit(const ErrorState('Erro de conexão. Verifique sua internet.'));
    }
  }

  /// Faz logout do usuário.
  Future<void> logout() async {
    emit(LoadingState());
    try {
      await _authService.signOut();
      emit(InitialState());
    } catch (e) {
      emit(const ErrorState('Erro ao fazer logout. Tente novamente.'));
    }
  }

  /// Verifica o status de autenticação do usuário.
  void checkAuthStatus() {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        emit(SuccessState<User>(user));
      } else {
        emit(InitialState());
      }
    } catch (e) {
      emit(InitialState());
    }
  }

  /// Traduz mensagens de erro do Supabase para português.
  String _translateAuthError(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();

    if (lowerError.contains('invalid login credentials') ||
        lowerError.contains('invalid credentials')) {
      return 'Email ou senha incorretos';
    }

    if (lowerError.contains('email not confirmed') ||
        lowerError.contains('email not verified')) {
      return 'Por favor, confirme seu email';
    }

    if (lowerError.contains('user already registered') ||
        lowerError.contains('user already exists')) {
      return 'Este email já está cadastrado';
    }

    if (lowerError.contains('password') && lowerError.contains('short')) {
      return 'A senha deve ter no mínimo 6 caracteres';
    }

    if (lowerError.contains('network') ||
        lowerError.contains('connection') ||
        lowerError.contains('timeout')) {
      return 'Erro de conexão. Verifique sua internet';
    }

    // Retorna a mensagem original se não houver tradução específica
    return errorMessage;
  }
}

