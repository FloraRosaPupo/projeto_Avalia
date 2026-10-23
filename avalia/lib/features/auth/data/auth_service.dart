// lib/core/services/auth_service.dart
// Serviço de autenticação que encapsula Supabase para facilitar testes

import 'package:supabase_flutter/supabase_flutter.dart';

/// Interface abstrata para serviços de autenticação
abstract class IAuthService {
  /// Faz login com email e senha
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  });

  /// Registra novo usuário
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  });

  /// Faz logout
  Future<void> signOut();

  /// Retorna o usuário atual
  User? get currentUser;
}

/// Implementação padrão usando Supabase
class SupabaseAuthService implements IAuthService {
  final SupabaseClient? _client;

  SupabaseAuthService([this._client]);

  SupabaseClient get client => _client ?? Supabase.instance.client;

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) {
    return client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  @override
  Future<void> signOut() {
    return client.auth.signOut();
  }

  @override
  User? get currentUser => client.auth.currentUser;
}
