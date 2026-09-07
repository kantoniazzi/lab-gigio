/// Erros como valor, não como exceção, nas fronteiras do sistema.
///
/// Motivação: num app de CAA, uma falha silenciosa é uma criança sem voz.
/// Forçar o chamador a tratar o caso de erro explicitamente — via `switch`
/// exaustivo sobre uma classe selada — torna impossível esquecer o caminho triste.
library;

import 'package:gigio/core/errors/app_error.dart';

sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(AppError error) = Err<T>;

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// Valor em caso de sucesso, ou `null` em caso de erro.
  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  /// Valor em caso de sucesso, ou [fallback] em caso de erro.
  T valueOr(T fallback) => valueOrNull ?? fallback;

  AppError? get errorOrNull => switch (this) {
        Ok<T>() => null,
        Err<T>(:final error) => error,
      };

  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Ok<T>(:final value) => Ok<R>(transform(value)),
        Err<T>(:final error) => Err<R>(error),
      };

  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
        Ok<T>(:final value) => transform(value),
        Err<T>(:final error) => Err<R>(error),
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;

  @override
  String toString() => 'Ok($value)';

  @override
  bool operator ==(Object other) => other is Ok<T> && other.value == value;

  @override
  int get hashCode => Object.hash('Ok', value);
}

final class Err<T> extends Result<T> {
  const Err(this.error);
  final AppError error;

  @override
  String toString() => 'Err($error)';

  @override
  bool operator ==(Object other) => other is Err<T> && other.error == error;

  @override
  int get hashCode => Object.hash('Err', error);
}
