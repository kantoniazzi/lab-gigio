/// A barra de frase — onde a criança vê o que está construindo.
///
/// Fica no topo e ocupa espaço generoso de propósito: é o produto da
/// comunicação, não um acessório. Tocá-la fala a frase inteira, que é o gesto
/// mais natural e o que os apps de CAA consagrados fazem.
library;

import 'package:flutter/material.dart';
import 'package:gigio/core/design_system/components/symbol_view.dart';
import 'package:gigio/core/design_system/tokens/gigio_tokens.dart';
import 'package:gigio/domain/models/sentence.dart';

class SentenceBar extends StatelessWidget {
  const SentenceBar({
    required this.sentence,
    required this.onSpeak,
    required this.onBackspace,
    required this.onClear,
    super.key,
  });

  final Sentence sentence;
  final VoidCallback onSpeak;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasWords = sentence.isNotEmpty;

    return Container(
      height: 104,
      margin: const EdgeInsets.fromLTRB(
        GigioSpacing.sm,
        GigioSpacing.sm,
        GigioSpacing.sm,
        0,
      ),
      decoration: BoxDecoration(
        color: GigioColors.sentenceBarBackground,
        borderRadius: BorderRadius.circular(GigioRadius.card),
        border: Border.all(color: GigioColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: hasWords
                  ? 'Falar a frase: ${sentence.displayText}'
                  : 'Barra de frase vazia',
              child: GestureDetector(
                onTap: hasWords ? onSpeak : null,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GigioSpacing.lg,
                    vertical: GigioSpacing.sm,
                  ),
                  child: hasWords
                      ? _WordStrip(sentence: sentence)
                      : const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Toque nos símbolos para montar sua frase',
                            style: GigioTypography.caption,
                          ),
                        ),
                ),
              ),
            ),
          ),
          _BarAction(
            icon: Icons.volume_up,
            tooltip: 'Falar',
            onPressed: hasWords ? onSpeak : null,
            emphasized: true,
          ),
          _BarAction(
            icon: Icons.backspace_outlined,
            tooltip: 'Apagar a última palavra',
            onPressed: hasWords ? onBackspace : null,
          ),
          _BarAction(
            icon: Icons.delete_sweep_outlined,
            tooltip: 'Limpar a frase',
            onPressed: hasWords ? onClear : null,
          ),
          const SizedBox(width: GigioSpacing.sm),
        ],
      ),
    );
  }
}

/// Mostra a frase como símbolos + texto, e não só texto.
///
/// Para uma criança não alfabetizada, a fita de símbolos é o que torna a frase
/// legível de volta — sem ela, a barra só serviria ao adulto.
class _WordStrip extends StatelessWidget {
  const _WordStrip({required this.sentence});

  final Sentence sentence;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: sentence.words.length,
      separatorBuilder: (_, _) => const SizedBox(width: GigioSpacing.sm),
      itemBuilder: (context, index) {
        final word = sentence.words[index];
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (word.symbolId != null)
              Expanded(
                child: SymbolView(
                  symbolId: word.symbolId!,
                  fallbackLabel: word.display,
                ),
              ),
            Text(
              word.display,
              style: word.symbolId != null
                  ? GigioTypography.body
                  : GigioTypography.sentenceBar,
            ),
          ],
        );
      },
    );
  }
}

class _BarAction extends StatelessWidget {
  const _BarAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.emphasized = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: emphasized ? 34 : 26,
        color: emphasized ? GigioColors.accent : GigioColors.textSecondary,
        // Garante que o alvo de toque respeite o mínimo mesmo com ícone menor.
        constraints: const BoxConstraints(
          minWidth: GigioAccessibility.minTouchTarget,
          minHeight: GigioAccessibility.minTouchTarget,
        ),
      ),
    );
  }
}
