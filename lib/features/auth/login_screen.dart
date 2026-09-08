/// Tela de entrada.
///
/// Deliberadamente sóbria e com alvo de toque grande: quem a vê pode ser a
/// própria Gigi, esperando um adulto aparecer. Nada aqui pisca, nada apressa.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigio/core/design_system/tokens/gigio_tokens.dart';
import 'package:gigio/core/result/result.dart';
import 'package:gigio/features/auth/auth_gate.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _entrando = false;
  String? _erro;

  Future<void> _entrar() async {
    setState(() {
      _entrando = true;
      _erro = null;
    });

    final resultado = await ref.read(authServiceProvider).entrar();
    if (!mounted) return;

    switch (resultado) {
      case Ok(:final value):
        ref.read(perfilProvider.notifier).definir(value);
      case Err(:final error):
        setState(() {
          _entrando = false;
          _erro = error.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GigioColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(GigioSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.record_voice_over_outlined,
                    size: 72,
                    color: GigioColors.accent,
                  ),
                  const SizedBox(height: GigioSpacing.lg),
                  Text('Gigio', style: GigioTypography.sentenceBar),
                  const SizedBox(height: GigioSpacing.sm),
                  const Text(
                    'Entre com a conta Google para começar.',
                    textAlign: TextAlign.center,
                    style: GigioTypography.body,
                  ),
                  const SizedBox(height: GigioSpacing.xxl),

                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: FilledButton.icon(
                      onPressed: _entrando ? null : _entrar,
                      icon: _entrando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.account_circle_outlined),
                      label: Text(
                        _entrando ? 'Entrando…' : 'Entrar com o Google',
                        style: const TextStyle(fontSize: 18),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: GigioColors.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(GigioRadius.card),
                        ),
                      ),
                    ),
                  ),

                  if (_erro != null) ...[
                    const SizedBox(height: GigioSpacing.lg),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(GigioSpacing.md),
                      decoration: BoxDecoration(
                        color: GigioColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(GigioRadius.card),
                      ),
                      child: Text(_erro!, style: GigioTypography.caption),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
