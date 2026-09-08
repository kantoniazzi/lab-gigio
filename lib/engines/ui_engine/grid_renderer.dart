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
          // Com coluna lateral, a grade principal divide o que sobra: as
          // colunas normais mais uma faixa lateral de 0.62 de célula.
          final sidebarUnits = page.sidebar.isEmpty ? 0.0 : 0.62;
          final horizontalGaps = gap * (page.columns - 1 + (sidebarUnits > 0 ? 1 : 0));
          final verticalGaps = gap * (page.rows - 1);

          // A célula acompanha a proporção do cartão do livro (quase quadrado).
          //
          // Sem isso, dividir a largura e a altura de forma independente produz
          // células largas e baixas em telas panorâmicas — como um celular
          // deitado. O desenho, que é quase quadrado, encolhe até caber na
          // altura e deixa um vão horizontal enorme dentro de cada célula, e a
          // grade parece esparramada.
          //
          // Fixando a proporção, a grade cresce até o limite da dimensão mais
          // apertada e depois é centralizada, mantendo a aparência do livro em
          // qualquer formato de tela.
          const aspectoDoCartao = 1.0;
          final unidadesHorizontais = page.columns + sidebarUnits;

          final alturaPelaLargura =
              (constraints.maxWidth - horizontalGaps) /
                  (unidadesHorizontais * aspectoDoCartao);
          final alturaPelaAltura =
              (constraints.maxHeight - verticalGaps) / page.rows;

          final cellHeight = alturaPelaLargura < alturaPelaAltura
              ? alturaPelaLargura
              : alturaPelaAltura;
          final cellWidth = cellHeight * aspectoDoCartao;

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

          Widget coluna(double largura, Widget Function(int) celula) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var row = 0; row < page.rows; row++) ...[
                    if (row > 0) const SizedBox(height: gap),
                    SizedBox(
                      width: largura,
                      height: cellHeight,
                      child: celula(row),
                    ),
                  ],
                ],
              );

          final grid = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var col = 0; col < page.columns; col++) ...[
                if (col > 0) const SizedBox(width: gap),
                coluna(cellWidth, (row) => _buildCell(row, col)),
              ],
              // A coluna lateral fica fora da grade de propósito: no PODD a
              // posição desses comandos é constante em todo o livro, e é isso
              // que os torna confiáveis para quem navega por memória.
              if (page.sidebar.isNotEmpty) ...[
                const SizedBox(width: gap),
                coluna(cellWidth * 0.62, _sidebarSlot),
              ],
            ],
          );

          // Centralizada: com proporção fixa sobra espaço na dimensão mais
          // folgada, e distribuí-lo em volta fica melhor que empurrar tudo
          // para um canto.
          return Center(child: grid);
        },
      ),
    );
  }

  Widget _sidebarSlot(int row) {
    for (final button in page.sidebar) {
      if (button.row != row) continue;
      if (button.hidden && !isEditing) return const SizedBox.shrink();
      return AacButtonWidget(
        button: button,
        isEditing: isEditing,
        onPressed: () => onButtonPressed(button),
        onEditPressed: () => onButtonEdit?.call(button),
      );
    }
    return const SizedBox.shrink();
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
