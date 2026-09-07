import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gigio/core/errors/app_error.dart';
import 'package:gigio/core/result/result.dart';
import 'package:gigio/domain/models/aac_button.dart';
import 'package:gigio/domain/models/board.dart';
import 'package:gigio/domain/models/button_action.dart';
import 'package:gigio/domain/models/word_class.dart';

/// Board mínimo e válido, usado como base nos testes de validação.
Map<String, Object?> validBoardJson() => {
      'schemaVersion': 1,
      'id': 'board-teste',
      'name': 'Board de teste',
      'homePageId': 'home',
      'pages': [
        {
          'id': 'home',
          'name': 'Principal',
          'rows': 2,
          'columns': 2,
          'buttons': [
            {
              'id': 'eu',
              'label': 'eu',
              'position': [0, 0],
              'wordClass': 'pronoun',
              'action': {'type': 'addWord', 'word': 'eu'},
            },
            {
              'id': 'comida',
              'label': 'Comida',
              'position': [0, 1],
              'wordClass': 'category',
              'action': {'type': 'navigate', 'target': 'comida'},
            },
          ],
        },
        {
          'id': 'comida',
          'name': 'Comida',
          'rows': 1,
          'columns': 1,
          'buttons': [
            {
              'id': 'agua',
              'label': 'água',
              'position': [0, 0],
              'symbol': 'water',
              'action': {'type': 'addWord', 'word': 'água'},
            },
          ],
        },
      ],
    };

BoardValidationError expectValidationError(Result<Board> result) {
  expect(result.isErr, isTrue, reason: 'Esperava rejeição, mas o board passou.');
  final error = result.errorOrNull;
  expect(error, isA<BoardValidationError>());
  return error! as BoardValidationError;
}

void main() {
  group('Board.fromJson — caminho feliz', () {
    test('lê um board válido', () {
      final result = Board.fromJson(validBoardJson());
      expect(result.isOk, isTrue, reason: result.errorOrNull?.message);

      final board = result.valueOrNull!;
      expect(board.name, 'Board de teste');
      expect(board.pages.length, 2);
      expect(board.homePage.id, 'home');
      expect(board.homePage.buttons.first.wordClass, WordClass.pronoun);
    });

    test('faz round-trip JSON sem perder informação', () {
      final original = Board.fromJson(validBoardJson()).valueOrNull!;

      final encoded = jsonEncode(original.toJson());
      final decoded =
          Board.fromJson(jsonDecode(encoded) as Map<String, Object?>).valueOrNull!;

      expect(decoded.id, original.id);
      expect(decoded.pages.length, original.pages.length);
      expect(
        decoded.page('comida')!.buttons.first.symbolId,
        'water',
      );
      expect(
        decoded.homePage.buttons.first.action,
        const AddWordAction(word: 'eu'),
      );
      // O round-trip precisa ser estável, senão salvar um board o degrada aos poucos.
      expect(jsonEncode(decoded.toJson()), encoded);
    });

    test('preserva spokenAs diferente do label', () {
      final json = validBoardJson();
      (((json['pages']! as List)[0] as Map<String, Object?>)['buttons']! as List)
          .add({
        'id': 'banheiro',
        'label': 'banheiro',
        'position': [1, 0],
        'action': {
          'type': 'addWord',
          'word': 'banheiro',
          'spokenAs': 'preciso ir ao banheiro',
        },
      });

      final board = Board.fromJson(json).valueOrNull!;
      final action = board.homePage.buttons
          .firstWhere((b) => b.id == 'banheiro')
          .action as AddWordAction;

      expect(action.spokenText, 'preciso ir ao banheiro');
    });
  });

  group('Board.fromJson — validação', () {
    test('rejeita arquivo sem schemaVersion', () {
      final json = validBoardJson()..remove('schemaVersion');
      expectValidationError(Board.fromJson(json));
    });

    test('rejeita schema mais novo que o suportado', () {
      final json = validBoardJson()..['schemaVersion'] = 99;
      final error = expectValidationError(Board.fromJson(json));
      expect(error.message, contains('Atualize'));
    });

    test('rejeita board cuja página inicial não existe', () {
      final json = validBoardJson()..['homePageId'] = 'inexistente';
      expectValidationError(Board.fromJson(json));
    });

    test('rejeita navegação para página inexistente', () {
      final json = validBoardJson();
      final homeButtons =
          ((json['pages']! as List)[0] as Map<String, Object?>)['buttons']! as List;
      (homeButtons[1] as Map<String, Object?>)['action'] = {
        'type': 'navigate',
        'target': 'pagina-fantasma',
      };

      final error = expectValidationError(Board.fromJson(json));
      expect(error.message, contains('pagina-fantasma'));
    });

    test('rejeita tipo de ação desconhecido em vez de ignorá-lo', () {
      // Um botão que não faz nada quando tocado é pior que um erro visível:
      // a criança tenta se comunicar e nada acontece.
      final json = validBoardJson();
      final homeButtons =
          ((json['pages']! as List)[0] as Map<String, Object?>)['buttons']! as List;
      (homeButtons[0] as Map<String, Object?>)['action'] = {
        'type': 'executarComandoArbitrario',
        'payload': 'rm -rf /',
      };

      final error = expectValidationError(Board.fromJson(json));
      expect(error.message, contains('desconhecido'));
    });

    test('rejeita botão fora dos limites da grade', () {
      final json = validBoardJson();
      final homeButtons =
          ((json['pages']! as List)[0] as Map<String, Object?>)['buttons']! as List;
      (homeButtons[0] as Map<String, Object?>)['position'] = [99, 99];

      final error = expectValidationError(Board.fromJson(json));
      expect(error.message, contains('fora da grade'));
    });

    test('rejeita dois botões na mesma posição', () {
      final json = validBoardJson();
      final homeButtons =
          ((json['pages']! as List)[0] as Map<String, Object?>)['buttons']! as List;
      (homeButtons[1] as Map<String, Object?>)['position'] = [0, 0];

      expectValidationError(Board.fromJson(json));
    });

    test('rejeita ids de botão duplicados na mesma página', () {
      final json = validBoardJson();
      final homeButtons =
          ((json['pages']! as List)[0] as Map<String, Object?>)['buttons']! as List;
      (homeButtons[1] as Map<String, Object?>)['id'] = 'eu';

      expectValidationError(Board.fromJson(json));
    });

    test('rejeita grade absurdamente grande', () {
      // Proteção contra board corrompido ou malicioso que tente esgotar memória.
      final json = validBoardJson();
      final home = (json['pages']! as List)[0] as Map<String, Object?>;
      home['rows'] = 100000;
      home['columns'] = 100000;

      expectValidationError(Board.fromJson(json));
    });

    test('rejeita board sem páginas', () {
      final json = validBoardJson()..['pages'] = <Object?>[];
      expectValidationError(Board.fromJson(json));
    });

    test('rejeita addWord com palavra vazia', () {
      final json = validBoardJson();
      final homeButtons =
          ((json['pages']! as List)[0] as Map<String, Object?>)['buttons']! as List;
      (homeButtons[0] as Map<String, Object?>)['action'] = {
        'type': 'addWord',
        'word': '   ',
      };

      expectValidationError(Board.fromJson(json));
    });
  });

  group('BoardPage', () {
    test('buttonAt encontra o botão pela posição', () {
      final board = Board.fromJson(validBoardJson()).valueOrNull!;
      expect(board.homePage.buttonAt(0, 0)?.id, 'eu');
      expect(board.homePage.buttonAt(1, 1), isNull);
    });

    test('withPage substitui a página sem alterar o board original', () {
      final board = Board.fromJson(validBoardJson()).valueOrNull!;
      final novaPagina = board.homePage.copyWith(name: 'Renomeada');
      final novoBoard = board.withPage(novaPagina);

      expect(novoBoard.homePage.name, 'Renomeada');
      expect(board.homePage.name, 'Principal');
    });
  });

  group('AacButton', () {
    test('copyWith consegue remover o símbolo explicitamente', () {
      const button = AacButton(
        id: 'x',
        label: 'x',
        row: 0,
        column: 0,
        action: AddWordAction(word: 'x'),
        symbolId: 'water',
      );

      expect(button.copyWith(clearSymbol: true).symbolId, isNull);
      expect(button.copyWith(label: 'y').symbolId, 'water');
    });
  });
}
