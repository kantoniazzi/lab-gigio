/// O que um botão FAZ — deliberadamente separado de como ele se PARECE.
///
/// Esta separação é a decisão arquitetural central do Gigio: o mesmo
/// `AacButton` visual pode adicionar uma palavra à frase, navegar para outra
/// página ou (no futuro) acender uma luz, sem que a camada de UI precise saber
/// a diferença.
///
/// Sendo uma classe selada, todo `switch` sobre uma ação é verificado em tempo
/// de compilação. Adicionar um tipo novo de ação quebra a compilação em todos
/// os pontos que precisam tratá-lo — que é exatamente o que queremos.
library;

import 'package:gigio/core/errors/app_error.dart';
import 'package:gigio/core/result/result.dart';

sealed class ButtonAction {
  const ButtonAction();

  /// Discriminador usado na serialização JSON.
  String get type;

  Map<String, Object?> toJson();

  /// Desserializa uma ação, validando o contrato.
  ///
  /// Rejeita tipos desconhecidos em vez de ignorá-los silenciosamente: um board
  /// importado com uma ação que este app não entende deve falhar de forma
  /// visível, e não produzir um botão que não faz nada quando a criança o toca.
  static Result<ButtonAction> fromJson(Map<String, Object?> json, {String? field}) {
    final type = json['type'];
    if (type is! String || type.isEmpty) {
      return Err(BoardValidationError(
        'A ação do botão não tem um campo "type" válido.',
        field: field,
      ));
    }

    String? requireString(String key) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value : null;
    }

    switch (type) {
      case AddWordAction.typeName:
        final word = requireString('word');
        if (word == null) {
          return Err(BoardValidationError(
            'A ação "adicionar palavra" precisa de um campo "word" não vazio.',
            field: field,
          ));
        }
        return Ok(AddWordAction(word: word, spokenAs: requireString('spokenAs')));

      case SpeakAction.typeName:
        final text = requireString('text');
        if (text == null) {
          return Err(BoardValidationError(
            'A ação "falar" precisa de um campo "text" não vazio.',
            field: field,
          ));
        }
        return Ok(SpeakAction(text));

      case NavigateAction.typeName:
        final target = requireString('target');
        if (target == null) {
          return Err(BoardValidationError(
            'A ação "navegar" precisa de um campo "target" não vazio.',
            field: field,
          ));
        }
        return Ok(NavigateAction(target));

      case NavigateBackAction.typeName:
        return const Ok(NavigateBackAction());
      case SpeakSentenceAction.typeName:
        return const Ok(SpeakSentenceAction());
      case ClearSentenceAction.typeName:
        return const Ok(ClearSentenceAction());
      case BackspaceAction.typeName:
        return const Ok(BackspaceAction());

      default:
        return Err(BoardValidationError(
          'Tipo de ação desconhecido: "$type". '
          'Este board pode ter sido criado numa versão mais nova do Gigio.',
          field: field,
        ));
    }
  }
}

/// Acrescenta uma palavra à barra de frase. É a ação mais comum num app de CAA.
final class AddWordAction extends ButtonAction {
  const AddWordAction({required this.word, this.spokenAs});

  static const typeName = 'addWord';

  /// Como a palavra aparece na barra de frase.
  final String word;

  /// Como a palavra é pronunciada, quando difere da escrita.
  /// Ex.: exibe "banheiro", fala "eu preciso ir ao banheiro".
  final String? spokenAs;

  String get spokenText => spokenAs ?? word;

  @override
  String get type => typeName;

  @override
  Map<String, Object?> toJson() => {
        'type': typeName,
        'word': word,
        if (spokenAs != null) 'spokenAs': spokenAs,
      };

  @override
  bool operator ==(Object other) =>
      other is AddWordAction && other.word == word && other.spokenAs == spokenAs;

  @override
  int get hashCode => Object.hash(typeName, word, spokenAs);
}

/// Fala um texto imediatamente, sem passar pela barra de frase.
/// Usado para frases prontas de uso frequente ("me ajuda", "estou com dor").
final class SpeakAction extends ButtonAction {
  const SpeakAction(this.text);

  static const typeName = 'speak';
  final String text;

  @override
  String get type => typeName;

  @override
  Map<String, Object?> toJson() => {'type': typeName, 'text': text};

  @override
  bool operator ==(Object other) => other is SpeakAction && other.text == text;

  @override
  int get hashCode => Object.hash(typeName, text);
}

/// Navega para outra página do board.
final class NavigateAction extends ButtonAction {
  const NavigateAction(this.targetPageId);

  static const typeName = 'navigate';
  final String targetPageId;

  @override
  String get type => typeName;

  @override
  Map<String, Object?> toJson() => {'type': typeName, 'target': targetPageId};

  @override
  bool operator ==(Object other) =>
      other is NavigateAction && other.targetPageId == targetPageId;

  @override
  int get hashCode => Object.hash(typeName, targetPageId);
}

/// Volta para a página anterior na pilha de navegação.
final class NavigateBackAction extends ButtonAction {
  const NavigateBackAction();
  static const typeName = 'back';

  @override
  String get type => typeName;

  @override
  Map<String, Object?> toJson() => {'type': typeName};

  @override
  bool operator ==(Object other) => other is NavigateBackAction;

  @override
  int get hashCode => typeName.hashCode;
}

/// Fala a frase inteira que está na barra.
final class SpeakSentenceAction extends ButtonAction {
  const SpeakSentenceAction();
  static const typeName = 'speakSentence';

  @override
  String get type => typeName;

  @override
  Map<String, Object?> toJson() => {'type': typeName};

  @override
  bool operator ==(Object other) => other is SpeakSentenceAction;

  @override
  int get hashCode => typeName.hashCode;
}

/// Limpa a barra de frase inteira.
final class ClearSentenceAction extends ButtonAction {
  const ClearSentenceAction();
  static const typeName = 'clear';

  @override
  String get type => typeName;

  @override
  Map<String, Object?> toJson() => {'type': typeName};

  @override
  bool operator ==(Object other) => other is ClearSentenceAction;

  @override
  int get hashCode => typeName.hashCode;
}

/// Remove a última palavra da barra de frase.
final class BackspaceAction extends ButtonAction {
  const BackspaceAction();
  static const typeName = 'backspace';

  @override
  String get type => typeName;

  @override
  Map<String, Object?> toJson() => {'type': typeName};

  @override
  bool operator ==(Object other) => other is BackspaceAction;

  @override
  int get hashCode => typeName.hashCode;
}
