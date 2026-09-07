/// O portão de entrada do modo de edição.
///
/// Dois obstáculos deliberados: pressão longa de 2 segundos **e** PIN. A
/// criança usa o app tocando símbolos rapidamente; nenhum toque comum abre
/// isso por acidente, que é o objetivo.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigio/core/design_system/tokens/gigio_tokens.dart';
import 'package:gigio/features/editor/board_editor_screen.dart';
import 'package:gigio/features/editor/caregiver_pin_service.dart';

final caregiverPinServiceProvider =
    Provider<CaregiverPinService>((ref) => CaregiverPinService());

class EditModeGate extends ConsumerStatefulWidget {
  const EditModeGate({super.key});

  @override
  ConsumerState<EditModeGate> createState() => _EditModeGateState();
}

class _EditModeGateState extends ConsumerState<EditModeGate> {
  double _progress = 0;

  Future<void> _onLongPress() async {
    final pin = await showDialog<String>(
      context: context,
      builder: (_) => const _PinDialog(),
    );
    if (pin == null || !mounted) return;

    final ok = await ref.read(caregiverPinServiceProvider).verify(pin);
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN incorreto.')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const BoardEditorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Modo de edição — mantenha pressionado por dois segundos',
      child: GestureDetector(
        onLongPress: _onLongPress,
        onLongPressStart: (_) => setState(() => _progress = 1),
        onLongPressEnd: (_) => setState(() => _progress = 0),
        onLongPressCancel: () => setState(() => _progress = 0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Retorno visual do progresso: sem isso, quem não sabe do gesto
            // não descobre que ele existe.
            SizedBox(
              width: GigioAccessibility.minTouchTarget,
              height: GigioAccessibility.minTouchTarget,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _progress),
                duration: _progress == 1
                    ? GigioAccessibility.editUnlockHold
                    : Duration.zero,
                builder: (context, value, _) => CircularProgressIndicator(
                  value: value == 0 ? 0 : value,
                  strokeWidth: 2.5,
                  color: GigioColors.editModeAccent,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
            const Icon(
              Icons.settings_outlined,
              color: GigioColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _PinDialog extends StatefulWidget {
  const _PinDialog();

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('PIN do cuidador'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 12,
            decoration: const InputDecoration(hintText: 'PIN'),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          const Text(
            'PIN inicial: 1234 — troque nas configurações.',
            style: GigioTypography.caption,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Entrar'),
        ),
      ],
    );
  }
}
