/// O board padrão é o que o app carrega na primeira execução — e o fallback
/// quando o board salvo corrompe. Se ele for inválido, o app abre vazio e a
/// criança fica sem voz. Por isso ele é validado no build, não em runtime.
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
    final raw = File('assets/boards/board_padrao.json').readAsStringSync();
    final result =
        Board.fromJson(jsonDecode(raw) as Map<String, Object?>);

    expect(
      result.isOk,
      isTrue,
      reason: 'O board padrão é inválido: ${result.errorOrNull?.message}',
    );
    board = result.valueOrNull!;
  });

  test('carrega e tem a página inicial esperada', () {
    expect(board.homePageId, 'home');
    expect(board.homePage.rows, 4);
    expect(board.homePage.columns, 5);
  });

  test('a página inicial está completamente preenchida', () {
    // Um buraco na grade inicial é quase sempre engano de edição do JSON.
    expect(board.homePage.buttons.length, board.homePage.capacity);
  });

  test('todo símbolo referenciado existe no catálogo', () {
    final quebrados = <String>[];

    for (final page in board.pages.values) {
      for (final button in page.buttons) {
        final id = button.symbolId;
        if (id == null) continue;
        if (SymbolCatalog.resolve(id) == null) {
          quebrados.add('${page.id}/${button.id} → "$id"');
        }
      }
    }

    expect(
      quebrados,
      isEmpty,
      reason: 'Botões apontando para símbolos inexistentes:\n  '
          '${quebrados.join('\n  ')}',
    );
  });

  test('toda página não-inicial tem como voltar', () {
    // Sem botão de voltar, a criança fica presa numa categoria — e o botão de
    // voltar do cabeçalho pode não ser óbvio para ela.
    final presas = <String>[];

    for (final page in board.pages.values) {
      if (page.id == board.homePageId) continue;
      final temVoltar = page.buttons.any((b) => b.action is NavigateBackAction);
      if (!temVoltar) presas.add(page.id);
    }

    expect(presas, isEmpty, reason: 'Páginas sem botão de voltar: $presas');
  });

  test('toda página é alcançável a partir da inicial', () {
    final alcancaveis = <String>{board.homePageId};
    final fila = <String>[board.homePageId];

    while (fila.isNotEmpty) {
      final atual = fila.removeLast();
      for (final button in board.pages[atual]!.buttons) {
        final action = button.action;
        if (action is NavigateAction && alcancaveis.add(action.targetPageId)) {
          fila.add(action.targetPageId);
        }
      }
    }

    final orfas = board.pages.keys.toSet().difference(alcancaveis);
    expect(orfas, isEmpty, reason: 'Páginas inalcançáveis: $orfas');
  });

  test('o vocabulário nuclear está na página inicial', () {
    // Estas são as palavras de maior frequência em CAA. Elas precisam estar na
    // tela de entrada, não escondidas dentro de categorias.
    const nucleo = {'eu', 'quero', 'mais', 'não', 'sim', 'acabou', 'ajuda'};

    final labels = board.homePage.buttons.map((b) => b.label.toLowerCase()).toSet();
    final faltando = nucleo.difference(labels);

    expect(faltando, isEmpty, reason: 'Vocabulário nuclear ausente: $faltando');
  });
}
