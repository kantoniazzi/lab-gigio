/// Erros de domínio do Gigio.
///
/// Todas as mensagens são em português porque são exibidas ao cuidador,
/// não a um desenvolvedor.
library;

sealed class AppError {
  const AppError(this.message);

  /// Mensagem já pronta para exibição ao cuidador.
  final String message;

  @override
  String toString() => '$runtimeType: $message';

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is AppError &&
      other.message == message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

/// O JSON de um board é inválido — estrutura, tipo ou valor fora do contrato.
final class BoardValidationError extends AppError {
  const BoardValidationError(super.message, {this.field});

  /// Caminho do campo problemático, ex.: `pages.home.buttons[3].action.type`.
  final String? field;

  @override
  String toString() =>
      field == null ? 'BoardValidationError: $message' : 'BoardValidationError [$field]: $message';

  @override
  bool operator ==(Object other) =>
      other is BoardValidationError && other.message == message && other.field == field;

  @override
  int get hashCode => Object.hash('BoardValidationError', message, field);
}

/// Falha ao ler ou gravar no armazenamento local.
final class StorageError extends AppError {
  const StorageError(super.message, {this.cause});
  final Object? cause;
}

/// Falha na síntese de voz.
final class SpeechError extends AppError {
  const SpeechError(super.message);
}

/// Falha de autenticação do cuidador (PIN).
final class AuthError extends AppError {
  const AuthError(super.message);
}
