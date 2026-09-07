/// Persistência de boards em JSON no diretório privado do app.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:gigio/core/errors/app_error.dart';
import 'package:gigio/core/result/result.dart';
import 'package:gigio/data/board_repository.dart';
import 'package:gigio/domain/models/board.dart';
import 'package:path_provider/path_provider.dart';

class JsonBoardStore implements BoardRepository {
  JsonBoardStore({Directory? directory}) : _overrideDirectory = directory;

  static const _fileName = 'board_ativo.json';
  static const _backupFileName = 'board_ativo.bak.json';
  static const _defaultBoardAsset = 'assets/boards/board_podd_gigi.json';

  final Directory? _overrideDirectory;

  Future<Directory> _dir() async =>
      _overrideDirectory ?? await getApplicationDocumentsDirectory();

  Future<File> _file() async => File('${(await _dir()).path}/$_fileName');
  Future<File> _backupFile() async =>
      File('${(await _dir()).path}/$_backupFileName');

  @override
  Future<Result<Board>> loadActiveBoard() async {
    final file = await _file();

    if (file.existsSync()) {
      final result = _decode(await file.readAsString());
      if (result.isOk) return result;

      // O board salvo está corrompido. Um board corrompido é, na prática, uma
      // criança sem voz — então tentamos o backup antes de desistir.
      final backup = await _backupFile();
      if (backup.existsSync()) {
        final fromBackup = _decode(await backup.readAsString());
        if (fromBackup.isOk) {
          // Restaura o backup como ativo para não repetir a recuperação.
          await _writeAtomically(await backup.readAsString());
          return fromBackup;
        }
      }
      // Último recurso: board de fábrica. Melhor um board genérico funcionando
      // do que um app que não abre.
    }

    return _loadDefaultBoard();
  }

  @override
  Future<Result<void>> saveBoard(Board board) async {
    try {
      final json = exportBoard(board);

      // Valida antes de gravar: nunca persistir algo que não conseguiríamos ler
      // de volta.
      final check = _decode(json);
      if (check.isErr) {
        return Err(StorageError(
          'O board não passou na validação e não foi salvo: '
          '${check.errorOrNull?.message}',
        ));
      }

      await _writeAtomically(json);
      return const Ok(null);
    } on Object catch (e) {
      return Err(StorageError('Não foi possível salvar o board.', cause: e));
    }
  }

  /// Grava sem nunca deixar o arquivo ativo num estado parcial.
  ///
  /// Sequência: preserva o ativo atual como backup → grava num temporário →
  /// `rename` (atômico no mesmo sistema de arquivos). Se o app morrer no meio,
  /// o que existe em disco é ou a versão antiga inteira, ou a nova inteira —
  /// nunca meio arquivo.
  Future<void> _writeAtomically(String json) async {
    final target = await _file();
    final backup = await _backupFile();
    final temp = File('${target.path}.tmp');

    if (target.existsSync()) {
      await target.copy(backup.path);
    }

    await temp.writeAsString(json, flush: true);
    await temp.rename(target.path);
  }

  @override
  Future<Result<Board>> resetToDefault() async {
    final result = await _loadDefaultBoard();
    if (result case Ok(:final value)) {
      final saved = await saveBoard(value);
      if (saved.isErr) return Err(saved.errorOrNull!);
    }
    return result;
  }

  Future<Result<Board>> _loadDefaultBoard() async {
    try {
      return _decode(await rootBundle.loadString(_defaultBoardAsset));
    } on Object catch (e) {
      return Err(StorageError(
        'Não foi possível carregar o board padrão do aplicativo.',
        cause: e,
      ));
    }
  }

  @override
  String exportBoard(Board board) =>
      const JsonEncoder.withIndent('  ').convert(board.toJson());

  @override
  Result<Board> importBoard(String json) => _decode(json);

  Result<Board> _decode(String json) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException catch (e) {
      return Err(BoardValidationError('O arquivo não é um JSON válido: ${e.message}'));
    }

    if (decoded is! Map<String, Object?>) {
      return const Err(BoardValidationError(
        'O arquivo não contém um board (esperava um objeto JSON).',
      ));
    }
    return Board.fromJson(decoded);
  }
}
