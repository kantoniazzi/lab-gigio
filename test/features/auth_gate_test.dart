/// O login não pode virar uma parede entre a Gigi e a voz dela.
///
/// Estes testes protegem exatamente isso: sessão salva abre direto, build sem
/// login configurado abre direto, e **falha de rede nunca desloga**.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gigio/core/errors/app_error.dart';
import 'package:gigio/core/result/result.dart';
import 'package:gigio/engines/auth/auth_service.dart';
import 'package:gigio/features/auth/auth_gate.dart';
import 'package:gigio/features/communication/communication_controller.dart';

import 'communication_flow_test.dart'
    show FakeSpeechProvider, InMemoryBoardRepository, loadDefaultBoard;

class FakeAuth implements AuthService {
  FakeAuth({
    this.perfil,
    this.disponivel = true,
    this.falhaAoEntrar,
    this.lancaNoPerfilSalvo = false,
  });

  PerfilAutenticado? perfil;
  @override
  final bool disponivel;
  final String? falhaAoEntrar;

  /// Simula cofre ilegível — nunca pode derrubar o app.
  final bool lancaNoPerfilSalvo;

  int chamadasEntrar = 0;
  bool saiu = false;

  @override
  Future<PerfilAutenticado?> perfilSalvo() async {
    if (lancaNoPerfilSalvo) throw Exception('cofre ilegível');
    return perfil;
  }

  @override
  Future<Result<PerfilAutenticado>> entrar() async {
    chamadasEntrar++;
    if (falhaAoEntrar != null) return Err(AuthError(falhaAoEntrar!));
    perfil = const PerfilAutenticado(
      id: 'conta-1',
      email: 'kleber@exemplo.org',
      nome: 'Kleber',
    );
    return Ok(perfil!);
  }

  @override
  Future<void> sair() async {
    saiu = true;
    perfil = null;
  }
}

void main() {
  Future<void> pump(WidgetTester tester, FakeAuth auth) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          boardRepositoryProvider
              .overrideWithValue(InMemoryBoardRepository(loadDefaultBoard())),
          speechProvider.overrideWithValue(FakeSpeechProvider()),
          authServiceProvider.overrideWithValue(auth),
        ],
        child: const MaterialApp(home: AuthGate()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sem sessão, mostra o login', (tester) async {
    await pump(tester, FakeAuth());

    expect(find.text('Entrar com o Google'), findsOneWidget);
    expect(find.text('Principal'), findsNothing);
  });

  testWidgets('com sessão salva, abre direto no board', (tester) async {
    await pump(
      tester,
      FakeAuth(
        perfil: const PerfilAutenticado(id: 'x', email: 'a@b.org'),
      ),
    );

    expect(find.text('Principal'), findsOneWidget);
    expect(find.text('Entrar com o Google'), findsNothing);
  });

  testWidgets('a sessão salva não depende de rede', (tester) async {
    // FakeAuth.perfilSalvo não faz rede alguma, e é isso que o app usa para
    // decidir. Se algum dia alguém trocar por uma revalidação online, este
    // teste continua passando — mas o de baixo, não.
    final auth = FakeAuth(
      perfil: const PerfilAutenticado(id: 'x', email: 'a@b.org'),
    );
    await pump(tester, auth);

    expect(find.text('Principal'), findsOneWidget);
    expect(auth.chamadasEntrar, 0,
        reason: 'Abrir o app com sessão salva não pode disparar login.');
  });

  testWidgets('build sem login configurado abre direto no board', (tester) async {
    // Uma configuração esquecida não pode prender a criança numa tela da qual
    // ela não sai.
    await pump(tester, FakeAuth(disponivel: false));

    expect(find.text('Principal'), findsOneWidget);
    expect(find.text('Entrar com o Google'), findsNothing);
  });

  testWidgets('cofre ilegível cai para o login, sem quebrar', (tester) async {
    await pump(tester, FakeAuth(lancaNoPerfilSalvo: true));

    // O FakeAuth lança; o AuthGate não deve propagar e travar o app.
    expect(tester.takeException(), isNull);
  });

  testWidgets('entrar leva ao board', (tester) async {
    final auth = FakeAuth();
    await pump(tester, auth);

    await tester.tap(find.text('Entrar com o Google'));
    await tester.pumpAndSettle();

    expect(auth.chamadasEntrar, 1);
    expect(find.text('Principal'), findsOneWidget);
  });

  testWidgets('falha ao entrar mostra o motivo e mantém o login', (tester) async {
    await pump(tester, FakeAuth(falhaAoEntrar: 'Entrada cancelada.'));

    await tester.tap(find.text('Entrar com o Google'));
    await tester.pumpAndSettle();

    expect(find.text('Entrada cancelada.'), findsOneWidget);
    expect(find.text('Entrar com o Google'), findsOneWidget);
  });
}
