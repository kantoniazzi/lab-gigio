/// Tela principal: barra de frase no topo, grade de símbolos abaixo.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigio/core/design_system/components/sentence_bar.dart';
import 'package:gigio/core/design_system/tokens/gigio_tokens.dart';
import 'package:gigio/engines/ui_engine/grid_renderer.dart';
import 'package:gigio/features/communication/communication_controller.dart';
import 'package:gigio/features/editor/edit_mode_gate.dart';

class CommunicationScreen extends ConsumerStatefulWidget {
  const CommunicationScreen({super.key});

  @override
  ConsumerState<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends ConsumerState<CommunicationScreen> {
  @override
  void initState() {
    super.initState();
    // `load` é assíncrono e mexe em provider; adiar para depois do primeiro
    // frame evita modificar estado durante a construção da árvore.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(communicationControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communicationControllerProvider);
    final controller = ref.read(communicationControllerProvider.notifier);

    if (state == null) {
      final fatal = controller.fatalLoadError;
      return Scaffold(
        backgroundColor: GigioColors.background,
        body: Center(
          child: fatal == null
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(GigioSpacing.xl),
                  child: Text(
                    fatal.message,
                    textAlign: TextAlign.center,
                    style: GigioTypography.body,
                  ),
                ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: GigioColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SentenceBar(
              sentence: state.sentence,
              onSpeak: controller.speakSentence,
              onBackspace: controller.backspace,
              onClear: controller.clearSentence,
            ),
            _PageHeader(
              pageName: state.currentPage.name,
              canGoBack: state.canGoBack,
              onBack: controller.goBack,
              onHome: controller.goHome,
            ),
            Expanded(
              child: GridRenderer(
                page: state.currentPage,
                onButtonPressed: controller.press,
              ),
            ),
            if (state.error != null)
              _ErrorBanner(
                message: state.error!.message,
                onDismiss: controller.dismissError,
              ),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.pageName,
    required this.canGoBack,
    required this.onBack,
    required this.onHome,
  });

  final String pageName;
  final bool canGoBack;
  final VoidCallback onBack;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GigioSpacing.md,
        vertical: GigioSpacing.xs,
      ),
      child: Row(
        children: [
          if (canGoBack)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Voltar',
              color: GigioColors.textSecondary,
            ),
          if (canGoBack)
            IconButton(
              onPressed: onHome,
              icon: const Icon(Icons.home_outlined),
              tooltip: 'Página inicial',
              color: GigioColors.textSecondary,
            ),
          const SizedBox(width: GigioSpacing.xs),
          Text(pageName, style: GigioTypography.heading),
          const Spacer(),
          // Único caminho para o editor, protegido por pressão longa + PIN.
          const EditModeGate(),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: GigioColors.danger.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(
        horizontal: GigioSpacing.lg,
        vertical: GigioSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: GigioColors.danger, size: 20),
          const SizedBox(width: GigioSpacing.sm),
          Expanded(child: Text(message, style: GigioTypography.caption)),
          TextButton(onPressed: onDismiss, child: const Text('OK')),
        ],
      ),
    );
  }
}
