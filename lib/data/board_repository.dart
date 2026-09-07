/// Contrato de persistência de boards.
///
/// Existe para que a escolha "JSON em arquivo" seja um detalhe substituível.
/// No MVP um board é um documento, e JSON é o formato natural — além de ser
/// exatamente o formato de import/export que queremos, sem camada de tradução.
/// Quando entrarem histórico de uso e predição de palavras, migrar para Drift/
/// SQLite será trocar a implementação, não o resto do app.
library;

import 'package:gigio/core/result/result.dart';
import 'package:gigio/domain/models/board.dart';

abstract interface class BoardRepository {
  /// Carrega o board ativo. Se nenhum foi salvo ainda, devolve o board padrão
  /// embarcado no app.
  Future<Result<Board>> loadActiveBoard();

  Future<Result<void>> saveBoard(Board board);

  /// Reverte para o board padrão de fábrica.
  Future<Result<Board>> resetToDefault();

  /// Serializa um board para texto, para compartilhamento/backup.
  String exportBoard(Board board);

  /// Lê um board a partir de texto JSON, validando o conteúdo.
  Result<Board> importBoard(String json);
}
