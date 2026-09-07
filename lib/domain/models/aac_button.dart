/// Um botão do board: posição na grade, aparência e ação.
library;

import 'package:gigio/core/errors/app_error.dart';
import 'package:gigio/core/result/result.dart';
import 'package:gigio/domain/models/button_action.dart';
import 'package:gigio/domain/models/word_class.dart';

class AacButton {
  const AacButton({
    required this.id,
    required this.label,
    required this.row,
    required this.column,
    required this.action,
    this.wordClass = WordClass.noun,
    this.symbolId,
    this.hidden = false,
  });

  final String id;

  /// Texto exibido sob o símbolo.
  final String label;

  final int row;
  final int column;

  final ButtonAction action;
  final WordClass wordClass;

  /// Identificador do símbolo no catálogo embarcado (ex.: `water`).
  ///
  /// É deliberadamente um *id*, e não um caminho de arquivo: um caminho vindo
  /// de um board importado seria um vetor de *path traversal*. O catálogo
  /// resolve o id para um asset conhecido, e um id desconhecido simplesmente
  /// não renderiza símbolo.
  final String? symbolId;

  /// Botão oculto mantém a posição na grade sem ser exibido. Permite ao
  /// cuidador simplificar o board sem reorganizar tudo — prática comum em CAA,
  /// já que mover símbolos de lugar prejudica a memória motora da criança.
  final bool hidden;

  AacButton copyWith({
    String? label,
    int? row,
    int? column,
    ButtonAction? action,
    WordClass? wordClass,
    String? symbolId,
    bool clearSymbol = false,
    bool? hidden,
  }) =>
      AacButton(
        id: id,
        label: label ?? this.label,
        row: row ?? this.row,
        column: column ?? this.column,
        action: action ?? this.action,
        wordClass: wordClass ?? this.wordClass,
        symbolId: clearSymbol ? null : (symbolId ?? this.symbolId),
        hidden: hidden ?? this.hidden,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'label': label,
        'position': [row, column],
        'wordClass': wordClass.toJson(),
        if (symbolId != null) 'symbol': symbolId,
        if (hidden) 'hidden': true,
        'action': action.toJson(),
      };

  static Result<AacButton> fromJson(
    Map<String, Object?> json, {
    required int rows,
    required int columns,
    String? field,
  }) {
    final id = json['id'];
    if (id is! String || id.trim().isEmpty) {
      return Err(BoardValidationError('Botão sem "id" válido.', field: field));
    }

    final label = json['label'];
    if (label is! String) {
      return Err(BoardValidationError('Botão "$id" sem "label" válido.', field: field));
    }

    final position = json['position'];
    if (position is! List || position.length != 2) {
      return Err(BoardValidationError(
        'Botão "$id" precisa de "position" no formato [linha, coluna].',
        field: field,
      ));
    }
    final row = position[0];
    final column = position[1];
    if (row is! int || column is! int) {
      return Err(BoardValidationError(
        'A posição do botão "$id" precisa ser de números inteiros.',
        field: field,
      ));
    }
    if (row < 0 || row >= rows || column < 0 || column >= columns) {
      return Err(BoardValidationError(
        'O botão "$id" está na posição ($row, $column), fora da grade '
        '${rows}x$columns.',
        field: field,
      ));
    }

    final rawAction = json['action'];
    if (rawAction is! Map<String, Object?>) {
      return Err(BoardValidationError('Botão "$id" sem "action".', field: field));
    }

    final symbol = json['symbol'];
    if (symbol != null && symbol is! String) {
      return Err(BoardValidationError(
        'O campo "symbol" do botão "$id" precisa ser texto.',
        field: field,
      ));
    }

    return ButtonAction.fromJson(rawAction, field: '$field.action').map(
      (action) => AacButton(
        id: id,
        label: label,
        row: row,
        column: column,
        action: action,
        wordClass: WordClass.fromJson(json['wordClass'] as String?),
        symbolId: symbol as String?,
        hidden: json['hidden'] == true,
      ),
    );
  }

  @override
  String toString() => 'AacButton($id, "$label", [$row,$column])';
}
