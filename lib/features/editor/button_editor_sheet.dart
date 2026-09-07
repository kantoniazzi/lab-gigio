/// Edição de um botão: rótulo, símbolo, classe gramatical e ação.
library;

import 'package:flutter/material.dart';
import 'package:gigio/core/design_system/components/symbol_view.dart';
import 'package:gigio/core/design_system/tokens/gigio_tokens.dart';
import 'package:gigio/core/symbols/symbol_catalog.dart';
import 'package:gigio/domain/models/aac_button.dart';
import 'package:gigio/domain/models/button_action.dart';
import 'package:gigio/domain/models/word_class.dart';

sealed class ButtonEditResult {
  const ButtonEditResult();
}

final class ButtonSaved extends ButtonEditResult {
  const ButtonSaved(this.button);
  final AacButton button;
}

final class ButtonDeleted extends ButtonEditResult {
  const ButtonDeleted();
}

class ButtonEditorSheet extends StatefulWidget {
  const ButtonEditorSheet({required this.button, this.isNew = false, super.key});

  final AacButton button;
  final bool isNew;

  @override
  State<ButtonEditorSheet> createState() => _ButtonEditorSheetState();
}

class _ButtonEditorSheetState extends State<ButtonEditorSheet> {
  late final TextEditingController _label =
      TextEditingController(text: widget.button.label);
  late final TextEditingController _spoken = TextEditingController(
    text: switch (widget.button.action) {
      AddWordAction(:final spokenAs) => spokenAs ?? '',
      SpeakAction(:final text) => text,
      _ => '',
    },
  );

  late WordClass _wordClass = widget.button.wordClass;
  late String? _symbolId = widget.button.symbolId;
  late _ActionKind _kind = _kindOf(widget.button.action);

  static _ActionKind _kindOf(ButtonAction action) => switch (action) {
        AddWordAction() => _ActionKind.addWord,
        SpeakAction() => _ActionKind.speak,
        NavigateAction() => _ActionKind.navigate,
        NavigateBackAction() => _ActionKind.back,
        SpeakSentenceAction() => _ActionKind.speakSentence,
        ClearSentenceAction() => _ActionKind.clear,
        BackspaceAction() => _ActionKind.backspace,
      };

  @override
  void dispose() {
    _label.dispose();
    _spoken.dispose();
    super.dispose();
  }

  ButtonAction? _buildAction() {
    final label = _label.text.trim();
    final spoken = _spoken.text.trim();

    return switch (_kind) {
      _ActionKind.addWord => label.isEmpty
          ? null
          : AddWordAction(
              word: label,
              spokenAs: spoken.isEmpty || spoken == label ? null : spoken,
            ),
      _ActionKind.speak =>
        spoken.isEmpty ? null : SpeakAction(spoken),
      // Trocar a ação para "navegar" exige escolher a página de destino, o que
      // não cabe neste MVP — a navegação vem do board padrão ou do JSON.
      _ActionKind.navigate => widget.button.action is NavigateAction
          ? widget.button.action
          : null,
      _ActionKind.back => const NavigateBackAction(),
      _ActionKind.speakSentence => const SpeakSentenceAction(),
      _ActionKind.clear => const ClearSentenceAction(),
      _ActionKind.backspace => const BackspaceAction(),
    };
  }

  void _save() {
    final action = _buildAction();
    if (action == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha o rótulo (e o texto falado, se for "falar").'),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      ButtonSaved(
        widget.button.copyWith(
          label: _label.text.trim(),
          action: action,
          wordClass: _wordClass,
          symbolId: _symbolId,
          clearSymbol: _symbolId == null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GigioSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isNew ? 'Novo botão' : 'Editar botão',
                style: GigioTypography.heading,
              ),
              const SizedBox(height: GigioSpacing.lg),

              TextField(
                controller: _label,
                decoration: const InputDecoration(
                  labelText: 'Rótulo',
                  helperText: 'O texto que aparece no botão',
                ),
              ),
              const SizedBox(height: GigioSpacing.md),

              DropdownButtonFormField<_ActionKind>(
                initialValue: _kind,
                decoration: const InputDecoration(labelText: 'O que este botão faz'),
                items: _ActionKind.values
                    .map((k) => DropdownMenuItem(value: k, child: Text(k.label)))
                    .toList(),
                onChanged: (v) => setState(() => _kind = v ?? _kind),
              ),

              if (_kind == _ActionKind.addWord || _kind == _ActionKind.speak) ...[
                const SizedBox(height: GigioSpacing.md),
                TextField(
                  controller: _spoken,
                  decoration: InputDecoration(
                    labelText: _kind == _ActionKind.speak
                        ? 'Texto falado'
                        : 'Texto falado (opcional)',
                    helperText: _kind == _ActionKind.speak
                        ? 'A frase inteira que será falada'
                        : 'Deixe vazio para falar o próprio rótulo',
                  ),
                ),
              ],

              const SizedBox(height: GigioSpacing.lg),
              const Text('Cor (classe gramatical)', style: GigioTypography.caption),
              const SizedBox(height: GigioSpacing.sm),
              Wrap(
                spacing: GigioSpacing.sm,
                runSpacing: GigioSpacing.sm,
                children: WordClass.values
                    .map(
                      (wc) => GestureDetector(
                        onTap: () => setState(() => _wordClass = wc),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: GigioSpacing.md,
                            vertical: GigioSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: GigioColors.forWordClass(wc),
                            borderRadius: BorderRadius.circular(GigioRadius.button),
                            border: Border.all(
                              color: _wordClass == wc
                                  ? GigioColors.editModeAccent
                                  : GigioColors.border,
                              width: _wordClass == wc ? 2.5 : 1,
                            ),
                          ),
                          child: Text(wc.label, style: GigioTypography.caption),
                        ),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: GigioSpacing.lg),
              const Text('Símbolo', style: GigioTypography.caption),
              const SizedBox(height: GigioSpacing.sm),
              _SymbolPicker(
                selected: _symbolId,
                onSelected: (id) => setState(() => _symbolId = id),
              ),

              const SizedBox(height: GigioSpacing.xl),
              Row(
                children: [
                  if (!widget.isNew)
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pop(const ButtonDeleted()),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remover'),
                      style: TextButton.styleFrom(
                        foregroundColor: GigioColors.danger,
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: GigioSpacing.sm),
                  FilledButton(onPressed: _save, child: const Text('Salvar')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SymbolPicker extends StatefulWidget {
  const _SymbolPicker({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  State<_SymbolPicker> createState() => _SymbolPickerState();
}

class _SymbolPickerState extends State<_SymbolPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final ids = SymbolCatalog.search(_query);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Buscar símbolo',
            isDense: true,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: GigioSpacing.sm),
        SizedBox(
          height: 180,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: GigioSpacing.sm,
              crossAxisSpacing: GigioSpacing.sm,
            ),
            itemCount: ids.length + 1,
            itemBuilder: (context, index) {
              // Primeira célula: remover o símbolo.
              if (index == 0) {
                return _PickerCell(
                  selected: widget.selected == null,
                  onTap: () => widget.onSelected(null),
                  child: const Icon(Icons.block, color: GigioColors.textSecondary),
                );
              }

              final id = ids[index - 1];
              return _PickerCell(
                selected: widget.selected == id,
                onTap: () => widget.onSelected(id),
                child: SymbolView(symbolId: id, fallbackLabel: id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PickerCell extends StatelessWidget {
  const _PickerCell({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(GigioSpacing.xs),
        decoration: BoxDecoration(
          color: GigioColors.surface,
          borderRadius: BorderRadius.circular(GigioRadius.button),
          border: Border.all(
            color: selected ? GigioColors.editModeAccent : GigioColors.border,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

enum _ActionKind {
  addWord('Adicionar palavra à frase'),
  speak('Falar uma frase pronta'),
  navigate('Ir para outra página'),
  back('Voltar'),
  speakSentence('Falar a frase montada'),
  clear('Limpar a frase'),
  backspace('Apagar a última palavra');

  const _ActionKind(this.label);
  final String label;
}

extension on WordClass {
  String get label => switch (this) {
        WordClass.pronoun => 'pessoa',
        WordClass.verb => 'verbo',
        WordClass.adjective => 'descrição',
        WordClass.noun => 'coisa',
        WordClass.social => 'social',
        WordClass.preposition => 'lugar',
        WordClass.question => 'pergunta',
        WordClass.negation => 'negação',
        WordClass.category => 'categoria',
        WordClass.system => 'controle',
      };
}
