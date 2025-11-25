import 'package:equatable/equatable.dart';

/// Classe base para gerenciamento de estados usando BLoC/Cubit.
abstract class BaseState extends Equatable {
  const BaseState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de qualquer ação.
class InitialState extends BaseState {}

/// Estado de carregamento (ex: buscando dados na API).
class LoadingState extends BaseState {}

/// Estado de sucesso contendo os dados retornados.
class SuccessState<T> extends BaseState {
  final T data;

  const SuccessState(this.data);

  @override
  List<Object?> get props => [data];
}

/// Estado de erro contendo a mensagem de falha.
class ErrorState extends BaseState {
  final String message;

  const ErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
