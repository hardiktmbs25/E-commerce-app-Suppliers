// lib/core/errors/failures.dart
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class FirestoreFailure extends Failure {
  const FirestoreFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local cache error.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}

// ── Result type ──────────────────────────────────────────────────────────────
// Simple Either-like wrapper without dartz dependency for simplicity
class Result<T> {
  final T? data;
  final Failure? failure;

  const Result.success(this.data) : failure = null;
  const Result.failure(this.failure) : data = null;

  bool get isSuccess => failure == null;
  bool get isFailure => failure != null;

  R fold<R>(R Function(Failure) onFailure, R Function(T) onSuccess) {
    if (isSuccess) return onSuccess(data as T);
    return onFailure(failure!);
  }
}