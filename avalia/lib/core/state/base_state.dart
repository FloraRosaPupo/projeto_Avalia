// lib/core/state/base_state.dart
import 'package:equatable/equatable.dart';

/// Base class for all Cubit states.
abstract class BaseState extends Equatable {
  const BaseState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the Cubit is first created.
class InitialState extends BaseState {}

/// State emitted while a request is in progress.
class LoadingState extends BaseState {}

/// State emitted when a request succeeds.
/// The generic type `T` holds the payload (e.g. a model object or raw JSON).
class SuccessState<T> extends BaseState {
  final T data;

  const SuccessState(this.data);

  @override
  List<Object?> get props => [data];
}

/// State emitted when a request fails.
class ErrorState extends BaseState {
  final String message;

  const ErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
