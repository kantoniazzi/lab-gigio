/// Testa o fluxo real de comunicação: tocar botões, montar frase, falar.
///
/// É o teste que mais importa no app: cobre o caminho que a criança percorre.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gigio/core/result/result.dart';
import 'package:gigio/data/board_repository.dart';
import 'package:gigio/domain/models/board.dart';
import 'package:gigio/engines/speech/speech_provider.dart';
import 'package:gigio/features/communication/communication_controller.dart';
import 'package:gigio/features/communication/communication_screen.dart';

/// Registra o que foi falado, para podermos afirmar sobre a saída de voz.
class FakeSpeechProvider implements SpeechProvider {
  final List<String> spoken = [];

  @override
  String get name => 'Fake';
  @override
  bool get worksOffline => true;

  @override
  Future<Result<void>> initialize() async => const Ok(null);

  @override
  Future<Result<void>> speak(String text) async {
    spoken.add(text);
    return const Ok(null);
  }

  @override
  Future<Result<void>> stop() async => const Ok(null);
  @override
  Future<List<SpeechVoice>> availableVoices() async => const [];
  @override
  Future<Result<void>> setVoice(SpeechVoice voice) async => const Ok(null);
  @override
  Future<Result<void>> setRate(double rate) async => const Ok(null);
  @override
  Future<Result<void>> setPitch(double pitch) async => const Ok(null);
  @override
  Future<void> dispose() async {}
}

class InMemoryBoardRepository implements BoardRepository {
  InMemoryBoardRepository(this._board);
  Board _board;

  Board get current => _board;
  int saveCount = 0;

  @override
  Future<Result<Board>> loadActiveBoard() async => Ok(_board);

  @override
  Future<Result<void>> saveBoard(Board board) async {
    _board = board;
    saveCount++;
    return const Ok(null);
  }

  @override
  Future<Result<Board>> resetToDefault() async => Ok(_board);

  @override
  String exportBoard(Board board) => jsonEncode(board.toJson());

  @override
  Result<Board> importBoard(String json) =>
      Board.fromJson(jsonDecode(json) as Map<String, Object?>);
}

Board loadDefaultBoard() {
  final raw = File('assets/boards/board_padrao.json').readAsStringSync();
  return Board.fromJson(jsonDecode(raw) as Map<String, Object?>).valueOrNull!;
}

void main() {
  late FakeSpeechProvider speech;
  late InMemoryBoardRepository repository;

  Future<void> pumpApp(WidgetTester tester) async {
    speech = FakeSpeechProvider();
    repository = InMemoryBoardRepository(loadDefaultBoard());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          boardRepositoryProvider.overrideWithValue(repository),
          speechProvider.overrideWithValue(speech),
        ],
        child: const MaterialApp(home: CommunicationScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mostra a página inicial com o vocabulário nuclear', (tester) async {
    await pumpApp(tester);

    expect(find.text('Principal'), findsOneWidget);
    expect(find.text('eu'), findsOneWidget);
    expect(find.text('quero'), findsOneWidget);
    expect(find.text('Toque nos símbolos para montar sua frase'), findsOneWidget);
  });

  testWidgets('monta "eu quero" e fala a frase completa', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('eu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('quero'));
    await tester.pumpAndSettle();

    // Cada toque ecoa a palavra: é o retorno que confirma à criança que
    // o toque funcionou.
    expect(speech.spoken, ['eu', 'quero']);

    // Tocar a barra de frase fala a sentença montada, capitalizada e pontuada.
    await tester.tap(find.byIcon(Icons.volume_up));
    await tester.pumpAndSettle();

    expect(speech.spoken.last, 'Eu quero.');
  });

  testWidgets('navega para uma categoria e volta', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Comida'));
    await tester.pumpAndSettle();
    expect(find.text('Comida'), findsWidgets);
    expect(find.text('água'), findsOneWidget);

    // O botão "voltar" da própria grade, que é o caminho que a criança usa.
    await tester.tap(find.text('voltar'));
    await tester.pumpAndSettle();
    expect(find.text('Principal'), findsOneWidget);
  });

  testWidgets('monta "eu quero água" atravessando páginas', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('eu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('quero'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('água'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.volume_up));
    await tester.pumpAndSettle();

    expect(speech.spoken.last, 'Eu quero água.');
  });

  testWidgets('apagar remove só a última palavra', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('eu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('quero'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.volume_up));
    await tester.pumpAndSettle();
    expect(speech.spoken.last, 'Eu.');
  });

  testWidgets('limpar esvazia a frase', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('eu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_sweep_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Toque nos símbolos para montar sua frase'), findsOneWidget);
  });

  testWidgets('frase pronta fala direto sem entrar na barra', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Sentimentos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('me ajuda!'));
    await tester.pumpAndSettle();

    expect(speech.spoken.last, 'Me ajuda, por favor!');
    // Não entrou na barra: a frase pronta é um atalho, não um bloco de montagem.
    expect(find.text('Toque nos símbolos para montar sua frase'), findsOneWidget);
  });
}
