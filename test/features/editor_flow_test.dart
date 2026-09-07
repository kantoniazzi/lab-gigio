/// Testa o requisito de "modificar os boards" ponta a ponta: passar pelo gate
/// do PIN, editar um botão e confirmar que a mudança foi persistida.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gigio/domain/models/button_action.dart';
import 'package:gigio/features/communication/communication_controller.dart';
import 'package:gigio/features/communication/communication_screen.dart';

import 'communication_flow_test.dart'
    show FakeSpeechProvider, InMemoryBoardRepository, loadDefaultBoard;

void main() {
  late FakeSpeechProvider speech;
  late InMemoryBoardRepository repository;

  setUp(() {
    // Sem valores iniciais, o serviço aceita o PIN padrão — que é exatamente o
    // estado de um app recém-instalado.
    FlutterSecureStorage.setMockInitialValues({});
  });

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

  Future<void> abrirEditor(WidgetTester tester, {String pin = '1234'}) async {
    await tester.longPress(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), pin);
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
  }

  testWidgets('o editor exige PIN e recusa o errado', (tester) async {
    await pumpApp(tester);
    await abrirEditor(tester, pin: '9999');

    expect(find.text('PIN incorreto.'), findsOneWidget);
    expect(find.textContaining('Editando:'), findsNothing);
  });

  testWidgets('o PIN correto abre o editor', (tester) async {
    await pumpApp(tester);
    await abrirEditor(tester);

    expect(find.textContaining('Editando:'), findsOneWidget);
  });

  testWidgets('editar o rótulo de um botão persiste a mudança', (tester) async {
    await pumpApp(tester);
    await abrirEditor(tester);

    // Toca no botão "eu" — no modo de edição, o toque abre o editor do botão
    // em vez de executar a ação.
    await tester.tap(find.text('eu').first);
    await tester.pumpAndSettle();
    expect(find.text('Editar botão'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'euzinho');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(repository.saveCount, greaterThan(0));

    final salvo = repository.current.homePage.buttons
        .firstWhere((b) => b.id == 'eu');
    expect(salvo.label, 'euzinho');
    // Editar o rótulo não deve corromper a ação do botão.
    expect(salvo.action, isA<AddWordAction>());
  });

  testWidgets('remover um botão o tira do board salvo', (tester) async {
    await pumpApp(tester);
    await abrirEditor(tester);

    final antes = repository.current.homePage.buttons.length;

    await tester.tap(find.text('gosto').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();

    expect(repository.current.homePage.buttons.length, antes - 1);
    expect(
      repository.current.homePage.buttons.any((b) => b.id == 'gosto'),
      isFalse,
    );
  });

  testWidgets('a edição sobrevive ao fechamento do editor', (tester) async {
    await pumpApp(tester);
    await abrirEditor(tester);

    await tester.tap(find.text('eu').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'EU');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    // Sai do editor e volta para a tela de comunicação.
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(find.text('EU'), findsOneWidget);
    expect(find.text('Principal'), findsOneWidget);
  });
}
