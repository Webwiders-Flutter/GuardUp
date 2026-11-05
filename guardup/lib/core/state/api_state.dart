import 'package:equatable/equatable.dart';

/// A reusable sealed class representing the lifecycle of an API operation
/// or async data flow.
///
/// Eliminates the need to recreate `initial`, `loading`, `success`, and `failure`
/// boilerplate for each feature or cubit.
sealed class ApiState<T> extends Equatable {
  const ApiState();

  /// Creates an initial, idle state before any action is performed.
  const factory ApiState.initial() = ApiInitial<T>;

  /// Creates a loading state, optionally retaining [previousData] for smooth transitions.
  const factory ApiState.loading({T? previousData}) = ApiLoading<T>;

  /// Creates a success state containing the resolved [data].
  const factory ApiState.success(T data) = ApiSuccess<T>;

  /// Creates a failure state containing a human-readable [message] and optional [error].
  const factory ApiState.failure(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    T? previousData,
  }) = ApiFailure<T>;

  /// Whether the state is [ApiInitial].
  bool get isInitial => this is ApiInitial<T>;

  /// Whether the state is [ApiLoading].
  bool get isLoading => this is ApiLoading<T>;

  /// Whether the state is [ApiSuccess].
  bool get isSuccess => this is ApiSuccess<T>;

  /// Whether the state is [ApiFailure].
  bool get isFailure => this is ApiFailure<T>;

  /// Returns the current or previous data if available, otherwise `null`.
  T? get dataOrNull => switch (this) {
    ApiSuccess<T>(:final data) => data,
    ApiLoading<T>(:final previousData) => previousData,
    ApiFailure<T>(:final previousData) => previousData,
    _ => null,
  };

  /// Returns the failure message if in [ApiFailure], otherwise `null`.
  String? get errorMessageOrNull => switch (this) {
    ApiFailure<T>(:final message) => message,
    _ => null,
  };

  /// Functional pattern matcher covering all states exhaustively.
  R when<R>({
    required R Function() initial,
    required R Function(T? previousData) loading,
    required R Function(T data) success,
    required R Function(String message, Object? error, T? previousData) failure,
  }) {
    return switch (this) {
      ApiInitial<T>() => initial(),
      ApiLoading<T>(:final previousData) => loading(previousData),
      ApiSuccess<T>(:final data) => success(data),
      ApiFailure<T>(:final message, :final error, :final previousData) =>
        failure(message, error, previousData),
    };
  }

  /// Optional pattern matcher with a fallback [orElse].
  R maybeWhen<R>({
    R Function()? initial,
    R Function(T? previousData)? loading,
    R Function(T data)? success,
    R Function(String message, Object? error, T? previousData)? failure,
    required R Function() orElse,
  }) {
    return switch (this) {
      ApiInitial<T>() => initial != null ? initial() : orElse(),
      ApiLoading<T>(:final previousData) =>
        loading != null ? loading(previousData) : orElse(),
      ApiSuccess<T>(:final data) => success != null ? success(data) : orElse(),
      ApiFailure<T>(:final message, :final error, :final previousData) =>
        failure != null ? failure(message, error, previousData) : orElse(),
    };
  }
}

/// The initial idle state.
final class ApiInitial<T> extends ApiState<T> {
  const ApiInitial();

  @override
  List<Object?> get props => [];
}

/// The loading state during an active request.
final class ApiLoading<T> extends ApiState<T> {
  final T? previousData;

  const ApiLoading({this.previousData});

  @override
  List<Object?> get props => [previousData];
}

/// The success state containing the fetched [data].
final class ApiSuccess<T> extends ApiState<T> {
  final T data;

  const ApiSuccess(this.data);

  @override
  List<Object?> get props => [data];
}

/// The failure state containing the error details.
final class ApiFailure<T> extends ApiState<T> {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final T? previousData;

  const ApiFailure(
    this.message, {
    this.error,
    this.stackTrace,
    this.previousData,
  });

  @override
  List<Object?> get props => [message, error, previousData];
}
