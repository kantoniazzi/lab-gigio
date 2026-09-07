/// Editor de boards.
///
/// Nota arquitetural: este editor manipula exatamente o mesmo modelo que o
/// renderizador consome. Não há caminho paralelo, nem formato intermediário —
/// é essa simetria que torna a funcionalidade "modificar os boards" barata em
/// vez de ser um subsistema inteiro.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigio/core/design_system/tokens/gigio_tokens.dart';
import 'package:gigio/core/result/result.dart';
import 'package:gigio/domain/models/aac_button.dart';
import 'package:gigio/domain/models/board.dart';
import 'package:gigio/domain/models/button_action.dart';
import 'package:gigio/engines/ui_engine/grid_renderer.dart';
import 'package:gigio/features/communication/communication_controller.dart';
import 'package:gigio/features/editor/button_editor_sheet.dart';

class BoardEditorScreen extends ConsumerWidget {
  const BoardEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communicationControllerProvider);
    final controller = ref.read(communicationControllerProvider.notifier);

    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final page = state.currentPage;

    Future<void> persist(Board board) async {
      final result = await controller.updateBoard(board);
      if (result case Err(:final error)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error.message)));
        }
      }
    }

    Future<void> editButton(AacButton button) async {
      final edited = await showModalBottomSheet<ButtonEditResult>(
        context: context,
        isScrollControlled: true,
        builder: (_) => ButtonEditorSheet(button: button),
      );
      if (edited == null) return;

      final buttons = [...page.buttons];
      final index = buttons.indexWhere((b) => b.id == button.id);
      if (index < 0) return;

      switch (edited) {
        case ButtonSaved(:final button):
          buttons[index] = button;
        case ButtonDeleted():
          buttons.removeAt(index);
      }
      await persist(state.board.withPage(page.copyWith(buttons: buttons)));
    }

    Future<void> addButton(int row, int column) async {
      final novo = AacButton(
        // Id derivado da posição e do instante evita colisão com ids existentes.
        id: 'btn-${DateTime.now().millisecondsSinceEpoch}-$row$column',
        label: 'novo',
        row: row,
        column: column,
        action: const AddWordAction(word: 'novo'),
      );

      final edited = await showModalBottomSheet<ButtonEditResult>(
        context: context,
        isScrollControlled: true,
        builder: (_) => ButtonEditorSheet(button: novo, isNew: true),
      );
      if (edited is! ButtonSaved) return;

      await persist(
        state.board.withPage(
          page.copyWith(buttons: [...page.buttons, edited.button]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: GigioColors.background,
      appBar: AppBar(
        backgroundColor: GigioColors.editModeAccent,
        foregroundColor: Colors.white,
        title: Text('Editando: ${page.name}'),
        actions: [
          IconButton(
            tooltip: 'Tamanho da grade',
            icon: const Icon(Icons.grid_view),
            onPressed: () async {
              final size = await showDialog<({int rows, int columns})>(
                context: context,
                builder: (_) =>
                    _GridSizeDialog(rows: page.rows, columns: page.columns),
              );
              if (size == null) return;

              // Botões que ficariam fora da nova grade seriam inválidos.
              // Preferimos avisar a descartar silenciosamente o trabalho do
              // cuidador.
              final orphans = page.buttons
                  .where((b) => b.row >= size.rows || b.column >= size.columns)
                  .toList();

              if (orphans.isNotEmpty && context.mounted) {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Reduzir a grade?'),
                    content: Text(
                      '${orphans.length} ${orphans.length == 1 ? "botão ficaria" : "botões ficariam"} '
                      'fora da nova grade e ${orphans.length == 1 ? "será removido" : "serão removidos"}: '
                      '${orphans.map((b) => b.label).join(", ")}.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Remover'),
                      ),
                    ],
                  ),
                );
                if (confirm != true) return;
              }

              await persist(
                state.board.withPage(
                  page.copyWith(
                    rows: size.rows,
                    columns: size.columns,
                    buttons: page.buttons
                        .where((b) => b.row < size.rows && b.column < size.columns)
                        .toList(),
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Concluir edição',
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: GigioColors.editModeAccent.withValues(alpha: 0.08),
              padding: const EdgeInsets.all(GigioSpacing.sm),
              child: const Text(
                'Toque num botão para editá-lo, ou num espaço vazio para criar um novo.',
                textAlign: TextAlign.center,
                style: GigioTypography.caption,
              ),
            ),
            Expanded(
              child: GridRenderer(
                page: page,
                isEditing: true,
                onButtonPressed: (_) {},
                onButtonEdit: editButton,
                onEmptyCellTap: addButton,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridSizeDialog extends StatefulWidget {
  const _GridSizeDialog({required this.rows, required this.columns});

  final int rows;
  final int columns;

  @override
  State<_GridSizeDialog> createState() => _GridSizeDialogState();
}

class _GridSizeDialogState extends State<_GridSizeDialog> {
  late int _rows = widget.rows;
  late int _columns = widget.columns;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tamanho da grade'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Stepper(
            label: 'Linhas',
            value: _rows,
            onChanged: (v) => setState(() => _rows = v),
          ),
          _Stepper(
            label: 'Colunas',
            value: _columns,
            onChanged: (v) => setState(() => _columns = v),
          ),
          const SizedBox(height: GigioSpacing.sm),
          const Text(
            'Grades menores deixam os botões maiores e mais fáceis de acertar.',
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
          onPressed: () =>
              Navigator.of(context).pop((rows: _rows, columns: _columns)),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GigioTypography.body),
        Row(
          children: [
            IconButton(
              onPressed: value > 1 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            SizedBox(
              width: 32,
              child: Text('$value',
                  textAlign: TextAlign.center, style: GigioTypography.heading),
            ),
            IconButton(
              onPressed: value < 12 ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }
}
