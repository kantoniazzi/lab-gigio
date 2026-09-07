/// Um board corrompido é, na prática, uma criança sem voz. Estes testes cobrem
/// o comportamento sob falha: escrita atômica, backup e recuperação.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gigio/core/result/result.dart';
import 'package:gigio/data/json_board_store.dart';
import 'package:gigio/domain/models/board.dart';

Board boardDePadrao() {
  final raw = File('assets/boards/board_padrao.json').readAsStringSync();
  return Board.fromJson(jsonDecode(raw) as Map<String, Object?>).valueOrNull!;
}

void main() {
  late Directory temp;
  late JsonBoardStore store;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('gigio_test_');
    store = JsonBoardStore(directory: temp);
  });

  tearDown(() => temp.deleteSync(recursive: true));

  test('salva e recarrega um board', () async {
    final original = boardDePadrao();

    expect((await store.saveBoard(original)).isOk, isTrue);

    final loaded = await store.loadActiveBoard();
    expect(loaded.isOk, isTrue);
    expect(loaded.valueOrNull!.pages.length, original.pages.length);
  });

  test('mantém backup da versão anterior ao salvar de novo', () async {
    final original = boardDePadrao();
    await store.saveBoard(original);
    await store.saveBoard(original.copyWith(name: 'Renomeado'));

    final backup = File('${temp.path}/board_ativo.bak.json');
    expect(backup.existsSync(), isTrue);
    expect(backup.readAsStringSync(), contains(original.name));
  });

  test('recupera do backup quando o board ativo corrompe', () async {
    final original = boardDePadrao();
    await store.saveBoard(original);
    await store.saveBoard(original.copyWith(name: 'Versão boa'));

    // Simula corrupção — queda de energia no meio da gravação, disco cheio,
    // arquivo truncado.
    File('${temp.path}/board_ativo.json').writeAsStringSync('{"schemaVer');

    final loaded = await store.loadActiveBoard();
    expect(loaded.isOk, isTrue,
        reason: 'Deveria ter recuperado a partir do backup.');
    expect(loaded.valueOrNull!.pages, isNotEmpty);
  });

  test('recusa salvar um board que não conseguiria reler', () async {
    // Board com página inicial inexistente: passaria pelo toJson, mas falharia
    // na releitura. Nunca deve chegar ao disco.
    final invalido = boardDePadrao().copyWith(homePageId: 'nao-existe');

    final result = await store.saveBoard(invalido);
    expect(result.isErr, isTrue);
    expect(File('${temp.path}/board_ativo.json').existsSync(), isFalse);
  });

  test('não deixa arquivo temporário para trás', () async {
    await store.saveBoard(boardDePadrao());

    final sobras = temp
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.tmp'))
        .toList();

    expect(sobras, isEmpty);
  });

  test('importBoard rejeita JSON malformado com mensagem legível', () {
    final result = store.importBoard('isso não é json');
    expect(result.isErr, isTrue);
    expect(result.errorOrNull!.message, contains('JSON'));
  });

  test('importBoard rejeita JSON válido que não é um board', () {
    expect(store.importBoard('[1, 2, 3]').isErr, isTrue);
    expect(store.importBoard('{"foo": "bar"}').isErr, isTrue);
  });

  test('export e import fazem round-trip', () {
    final original = boardDePadrao();
    final reimported = store.importBoard(store.exportBoard(original));

    expect(reimported.isOk, isTrue);
    expect(reimported.valueOrNull!.pages.length, original.pages.length);
  });
}
