/// Transforma um `BoardPage` — que é dado — numa grade de widgets.
///
/// É a peça que torna o board declarativo: a tela não é escrita à mão em Dart,
/// ela é *calculada* a partir do modelo. Sem isto, o editor de boards teria que
/// gerar código; com isto, ele só edita dados.
library;

import 'package:flutter/material.dart';
import 'package:gigio/core/design_system/components/aac_button_widget.dart';
import 'package:gigio/core/design_system/tokens/gigio_tokens.dart';
import 'package:gigio/domain/models/aac_button.dart';
import 'package:gigio/domain/models/board.dart';

class GridRenderer extends StatelessWidget {
  const GridRenderer({
    required this.page,
    required this.onButtonPressed,
    this.isEditing = false,
    this.onButtonEdit,
    this.onEmptyCellTap,
    super.key,
  });

  final BoardPage page;
  final void Function(AacButton button) onButtonPressed;

  final bool isEditing;
  final void Function(AacButton button)? onButtonEdit;
  final void Function(int row, int column)? onEmptyCellTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(GigioSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = GigioSpacing.sm;
          final cellWidth =
              (constraints.maxWidth - gap * (page.columns - 1)) / page.columns;
          final cellHeight =
              (constraints.maxHeight - gap * (page.rows - 1)) / page.rows;

          // Avisa quando a grade configurada não cabe com toque confortável.
          // Não bloqueamos a renderização: um botão pequeno ainda comunica,
          // e a decisão sobre densidade é clínica, do cuidador — não nossa.
          assert(() {
            if (cellWidth < GigioAccessibility.minTouchTarget ||
                cellHeight < GigioAccessibility.minTouchTarget) {
              debugPrint(
                'Gigio: a grade ${page.rows}x${page.columns} da página '
                '"${page.id}" gera células de '
                '${cellWidth.toStringAsFixed(0)}x${cellHeight.toStringAsFixed(0)}pt, '
                'abaixo do alvo mínimo de toque de '
                '${GigioAccessibility.minTouchTarget}pt.',
              );
            }
            return true;
          }());

          return Column(
            children: [
              for (var row = 0; row < page.rows; row++) ...[
                if (row > 0) const SizedBox(height: gap),
                SizedBox(
                  height: cellHeight,
                  child: Row(
                    children: [
                      for (var col = 0; col < page.columns; col++) ...[
                        if (col > 0) const SizedBox(width: gap),
                        SizedBox(
                          width: cellWidth,
                          child: _buildCell(row, col),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildCell(int row, int column) {
    final button = page.buttonAt(row, column);

    if (button == null || (button.hidden && !isEditing)) {
      return EmptyCellWidget(
        isEditing: isEditing,
        onTap: () => onEmptyCellTap?.call(row, column),
      );
    }

    return Opacity(
      // No modo de edição, um botão oculto aparece esmaecido para que o
      // cuidador saiba que ele existe e possa reexibi-lo.
      opacity: button.hidden ? 0.35 : 1.0,
      child: AacButtonWidget(
        button: button,
        isEditing: isEditing,
        onPressed: () => onButtonPressed(button),
        onEditPressed: () => onButtonEdit?.call(button),
      ),
    );
  }
}
