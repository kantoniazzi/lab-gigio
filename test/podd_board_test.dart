/// O board PODD é a réplica digital do livro que a Gigi já usa. Um destino
/// errado a manda para outra página no meio de uma frase — por isso a
/// integridade é verificada no build, não em campo.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gigio/core/symbols/symbol_catalog.dart';
import 'package:gigio/domain/models/board.dart';
import 'package:gigio/domain/models/button_action.dart';

void main() {
  late Board board;

  setUpAll(() {
    final raw = File('assets/boards/board_podd_gigi.json').readAsStringSync();
    final result = Board.fromJson(jsonDecode(raw) as Map<String, Object?>);
    expect(result.isOk, isTrue,
        reason: 'Board PODD inválido: ${result.errorOrNull?.message}');
    board = result.valueOrNull!;
  });

  test('abre na página 1a, como o livro de papel', () {
    expect(board.homePageId, '1a');
    expect(board.schemaVersion, 2);
  });

  test('as páginas transcritas usam a grade 4x3 do livro', () {
    final transcritas = board.pages.values.where((p) => p.columns == 4);
    expect(transcritas.length, 56);
    for (final page in transcritas) {
      expect(page.rows, 3, reason: 'Página ${page.id} fora da grade PODD');
    }
  });

  test('toda página transcrita tem "ooops" na coluna lateral', () {
    // O reparo de comunicação é o que permite à criança dizer "não foi isso
    // que eu quis dizer". No PODD ele está em toda página, sempre no mesmo
    // lugar — e é isso que o torna confiável.
    for (final page in board.pages.values.where((p) => p.columns == 4)) {
      final temOoops = page.sidebar.any((b) => b.label == 'ooops');
      expect(temOoops, isTrue, reason: 'Página ${page.id} sem "ooops"');
    }
  });

  test('toda página não-inicial oferece caminho de volta', () {
    for (final page in board.pages.values) {
      if (page.id == board.homePageId) continue;
      final temVolta = [...page.buttons, ...page.sidebar].any(
        (b) => b.action is NavigateBackAction ||
            (b.action is NavigateAction &&
                (b.action as NavigateAction).targetPageId == board.homePageId),
      );
      expect(temVolta, isTrue, reason: 'Página ${page.id} sem saída');
    }
  });

  test('todo destino de navegação existe (real ou stub)', () {
    // Board.fromJson já rejeitaria um destino inexistente; este teste torna a
    // intenção explícita e falha com mensagem melhor.
    for (final page in board.pages.values) {
      for (final button in [...page.buttons, ...page.sidebar]) {
        final action = button.action;
        if (action is! NavigateAction) continue;
        expect(board.page(action.targetPageId), isNotNull,
            reason: '${page.id}/${button.id} → ${action.targetPageId}');
      }
    }
  });

  test('toda célula transcrita aponta para uma imagem existente', () {
    final quebrados = <String>[];
    for (final page in board.pages.values) {
      for (final button in [...page.buttons, ...page.sidebar]) {
        final id = button.symbolId;
        if (id == null) continue;
        if (SymbolCatalog.resolve(id) == null) quebrados.add('${page.id}/${button.id}');
      }
    }
    expect(quebrados, isEmpty, reason: 'Símbolos inexistentes: $quebrados');
  });

  test('toda página é alcançável a partir da inicial', () {
    final vistas = <String>{board.homePageId};
    final fila = [board.homePageId];
    while (fila.isNotEmpty) {
      final atual = fila.removeLast();
      final page = board.pages[atual]!;
      for (final button in [...page.buttons, ...page.sidebar]) {
        final action = button.action;
        if (action is NavigateAction && vistas.add(action.targetPageId)) {
          fila.add(action.targetPageId);
        }
      }
    }
    expect(board.pages.keys.toSet().difference(vistas), isEmpty);
  });
}
