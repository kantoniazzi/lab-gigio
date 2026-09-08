/// Configurações do cuidador: PIN, voz e consentimento de telemetria.
///
/// Só é alcançável depois do gate de PIN, junto com o editor de boards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigio/core/design_system/tokens/gigio_tokens.dart';
import 'package:gigio/core/result/result.dart';
import 'package:gigio/features/communication/communication_controller.dart';
import 'package:gigio/features/auth/auth_gate.dart';
import 'package:gigio/features/editor/caregiver_pin_service.dart';

final caregiverPinServiceProvider =
    Provider<CaregiverPinService>((ref) => CaregiverPinService());

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late bool _consentimento = ref.read(telemetryProvider).consentimentoAtivo;

  Future<void> _trocarPin() async {
    final pin = await showDialog<String>(
      context: context,
      builder: (_) => const _NovoPinDialog(),
    );
    if (pin == null || !mounted) return;

    final resultado = await ref.read(caregiverPinServiceProvider).setPin(pin);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(switch (resultado) {
        Ok() => 'PIN atualizado.',
        Err(:final error) => error.message,
      }),
    ));
  }

  Future<void> _sair() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Será preciso entrar de novo na próxima vez que o aplicativo abrir. '
          'O board e as personalizações continuam no aparelho.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;

    await ref.read(authServiceProvider).sair();
    if (!mounted) return;
    ref.read(perfilProvider.notifier).definir(null);
    // Volta ao portão, que vai mostrar o login.
    Navigator.of(context).popUntil((rota) => rota.isFirst);
  }

  Future<void> _alternarConsentimento(bool ativo) async {
    if (ativo) {
      final confirmou = await showDialog<bool>(
        context: context,
        builder: (_) => const _ConsentimentoDialog(),
      );
      if (confirmou != true) return;
    }
    await ref.read(telemetryProvider).definirConsentimento(ativo: ativo);
    if (mounted) setState(() => _consentimento = ativo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GigioColors.background,
      appBar: AppBar(
        backgroundColor: GigioColors.editModeAccent,
        foregroundColor: Colors.white,
        title: const Text('Configurações'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(GigioSpacing.lg),
          children: [
            const Text('Acesso', style: GigioTypography.heading),
            const SizedBox(height: GigioSpacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_outline),
              title: const Text('Trocar o PIN do cuidador'),
              subtitle: const Text(
                'O PIN impede que a criança abra o editor por acidente. '
                'Ele não protege contra um adulto com o aparelho — para isso, '
                'use o Acesso Guiado do iPad.',
                style: GigioTypography.caption,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _trocarPin,
            ),
            if (ref.watch(authServiceProvider).disponivel)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout),
                title: const Text('Sair da conta'),
                subtitle: Text(
                  ref.watch(perfilProvider)?.nomeExibido ??
                      'Nenhuma conta conectada',
                  style: GigioTypography.caption,
                ),
                onTap: _sair,
              ),
            const Divider(height: GigioSpacing.xxl),

            const Text('Privacidade', style: GigioTypography.heading),
            const SizedBox(height: GigioSpacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _consentimento,
              onChanged: _alternarConsentimento,
              title: const Text('Compartilhar como o app é usado'),
              subtitle: const Text(
                'Desligado, o aplicativo envia apenas falhas técnicas. '
                'Ligado, envia também quais páginas foram abertas e quais '
                'botões foram tocados.',
                style: GigioTypography.caption,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(GigioSpacing.md),
              decoration: BoxDecoration(
                color: GigioColors.danger.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(GigioRadius.card),
              ),
              child: const Text(
                'As frases nunca são enviadas — nem o texto, nem os rótulos dos '
                'botões. Ainda assim, saber quais páginas foram abertas revela '
                'muito: este livro tem páginas chamadas "algo está errado", '
                '"partes do corpo" e "banheiro". Só ligue se estiver confortável '
                'com isso.',
                style: GigioTypography.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NovoPinDialog extends StatefulWidget {
  const _NovoPinDialog();

  @override
  State<_NovoPinDialog> createState() => _NovoPinDialogState();
}

class _NovoPinDialogState extends State<_NovoPinDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo PIN'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          hintText: 'Ao menos 4 dígitos',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _ConsentimentoDialog extends StatelessWidget {
  const _ConsentimentoDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmar compartilhamento'),
      content: const SingleChildScrollView(
        child: Text(
          'Ao ligar, o aplicativo passa a enviar quais páginas foram abertas e '
          'quais botões foram tocados.\n\n'
          'Isso permite entender como o livro é usado, mas também revela sobre '
          'o que a criança se comunicou — inclusive dor, desconforto e recusa.\n\n'
          'Você pode desligar a qualquer momento, e o que ainda não tiver sido '
          'enviado é descartado.\n\n'
          'Só um responsável legal pode dar esse consentimento.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Não ligar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sou responsável e autorizo'),
        ),
      ],
    );
  }
}
