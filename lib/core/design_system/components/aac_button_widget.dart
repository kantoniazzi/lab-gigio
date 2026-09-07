/// O componente mais importante do app.
///
/// Nota arquitetural: este widget **não sabe o que o botão faz**. Ele recebe um
/// modelo e um callback. É isto que permite que a mesma aparência sirva para
/// adicionar uma palavra, navegar entre páginas ou, no futuro, acender uma luz.
library;

import 'package:flutter/material.dart';
import 'package:gigio/core/design_system/components/symbol_view.dart';
import 'package:gigio/core/design_system/tokens/gigio_tokens.dart';
import 'package:gigio/domain/models/aac_button.dart';

class AacButtonWidget extends StatefulWidget {
  const AacButtonWidget({
    required this.button,
    required this.onPressed,
    this.isEditing = false,
    this.onEditPressed,
    super.key,
  });

  final AacButton button;
  final VoidCallback onPressed;

  /// No modo de edição o toque abre o editor do botão em vez de executar a ação.
  final bool isEditing;
  final VoidCallback? onEditPressed;

  @override
  State<AacButtonWidget> createState() => _AacButtonWidgetState();
}

class _AacButtonWidgetState extends State<AacButtonWidget> {
  bool _pressed = false;

  void _handleTap() {
    if (widget.isEditing) {
      widget.onEditPressed?.call();
      return;
    }
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final button = widget.button;
    final background = GigioColors.forWordClass(button.wordClass);

    return Semantics(
      button: true,
      label: button.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: _handleTap,
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: GigioMotion.tap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // O rótulo acompanha o tamanho da célula: numa grade 3x3 num
              // iPad o texto fica grande, numa 8x8 ele encolhe sem estourar.
              final fontSize = (constraints.maxHeight * 0.16).clamp(
                GigioTypography.buttonLabelMin,
                GigioTypography.buttonLabelMax,
              );

              if (button.labelInImage) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: SymbolView(
                        symbolId: button.symbolId ?? '',
                        fallbackLabel: button.label,
                      ),
                    ),
                    if (widget.isEditing)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            color: GigioColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: GigioColors.editModeAccent,
                          ),
                        ),
                      ),
                  ],
                );
              }

              return Container(
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(GigioRadius.button),
                  border: Border.all(
                    color: widget.isEditing
                        ? GigioColors.editModeAccent
                        : GigioColors.border,
                    width: widget.isEditing ? 2.5 : 1,
                  ),
                ),
                padding: const EdgeInsets.all(GigioSpacing.xs),
                child: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (button.symbolId != null)
                          Expanded(
                            child: SymbolView(
                              symbolId: button.symbolId!,
                              fallbackLabel: button.label,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: GigioSpacing.xs),
                          // `scaleDown` encolhe rótulos longos em vez de
                          // quebrá-los no meio da palavra ("Sentiment/os").
                          // Um rótulo partido atrapalha quem está aprendendo a
                          // associar a palavra escrita ao símbolo.
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              button.label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w600,
                                color: GigioColors.textOnAccent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.isEditing)
                      const Positioned(
                        top: 0,
                        right: 0,
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: GigioColors.editModeAccent,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Célula vazia da grade. No modo normal é invisível; no modo de edição vira um
/// alvo para adicionar um botão naquela posição.
class EmptyCellWidget extends StatelessWidget {
  const EmptyCellWidget({required this.isEditing, this.onTap, super.key});

  final bool isEditing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (!isEditing) return const SizedBox.shrink();

    return Semantics(
      button: true,
      label: 'Adicionar botão nesta posição',
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GigioRadius.button),
            border: Border.all(
              color: GigioColors.editModeAccent.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: const Center(
            child: Icon(Icons.add, color: GigioColors.editModeAccent),
          ),
        ),
      ),
    );
  }
}
