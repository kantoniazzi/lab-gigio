/// Decide o que a Gigi vê ao abrir o app.
///
/// Com sessão salva — ou com o login desativado nesta build — vai direto para o
/// board. Sem sessão, mostra o login.
///
/// **A leitura da sessão não usa rede.** Isso é deliberado: revalidar com o
/// Google a cada abertura significaria que um dia sem internet deixa a criança
/// sem voz. O login acontece uma vez; depois disso o app abre sempre.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigio/core/design_system/tokens/gigio_tokens.dart';
import 'package:gigio/engines/auth/auth_service.dart';
import 'package:gigio/features/auth/login_screen.dart';
import 'package:gigio/features/communication/communication_screen.dart';

final authServiceProvider = Provider<AuthService>((ref) => const AuthDesativado());

/// Perfil em vigor. `null` significa "ainda não entrou".
class PerfilNotifier extends Notifier<PerfilAutenticado?> {
  @override
  PerfilAutenticado? build() => null;

  void definir(PerfilAutenticado? perfil) => state = perfil;
}

final perfilProvider =
    NotifierProvider<PerfilNotifier, PerfilAutenticado?>(PerfilNotifier.new);

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restaurarSessao());
  }

  Future<void> _restaurarSessao() async {
    PerfilAutenticado? perfil;
    try {
      perfil = await ref.read(authServiceProvider).perfilSalvo();
    } on Object {
      // Cofre ilegível, plugin indisponível, o que for: cai para o login em vez
      // de derrubar o app. Uma exceção aqui deixaria a Gigi sem conseguir nem
      // abrir o aplicativo, que é o pior desfecho possível.
      perfil = null;
    }
    if (!mounted) return;

    ref.read(perfilProvider.notifier).definir(perfil);
    setState(() => _carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        backgroundColor: GigioColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final auth = ref.watch(authServiceProvider);
    final perfil = ref.watch(perfilProvider);

    // Build sem client ID configurado abre direto no board. Uma configuração
    // esquecida não pode prender a criança numa tela da qual ela não sai.
    if (!auth.disponivel || perfil != null) {
      return const CommunicationScreen();
    }

    return const LoginScreen();
  }
}
