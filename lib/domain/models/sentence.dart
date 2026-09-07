/// A frase em construção na barra superior.
///
/// Imutável: cada operação devolve uma nova frase. Isso torna o histórico de
/// desfazer trivial e elimina uma classe inteira de bugs de estado
/// compartilhado.
library;

/// Uma palavra na frase: o que se lê e o que se fala podem divergir.
class SentenceWord {
  const SentenceWord({required this.display, String? spoken, this.symbolId})
      // ignore: prefer_initializing_formals
      : _spoken = spoken;

  final String display;
  final String? _spoken;
  final String? symbolId;

  String get spoken => _spoken ?? display;

  @override
  bool operator ==(Object other) =>
      other is SentenceWord &&
      other.display == display &&
      other.spoken == spoken &&
      other.symbolId == symbolId;

  @override
  int get hashCode => Object.hash(display, spoken, symbolId);

  @override
  String toString() => 'SentenceWord($display)';
}

class Sentence {
  const Sentence(this.words);
  const Sentence.empty() : words = const [];

  final List<SentenceWord> words;

  bool get isEmpty => words.isEmpty;
  bool get isNotEmpty => words.isNotEmpty;
  int get length => words.length;

  /// Texto exibido na barra de frase.
  String get displayText => words.map((w) => w.display).join(' ');

  /// Texto entregue ao sintetizador de voz.
  ///
  /// Recebe letra maiúscula inicial e ponto final: sem isso, os sintetizadores
  /// tendem a ler a frase com entonação de lista, e não de sentença.
  String get spokenText {
    if (words.isEmpty) return '';
    final raw = words.map((w) => w.spoken).join(' ').trim();
    if (raw.isEmpty) return '';
    final capitalized = raw[0].toUpperCase() + raw.substring(1);
    const terminators = {'.', '!', '?'};
    return terminators.contains(capitalized[capitalized.length - 1])
        ? capitalized
        : '$capitalized.';
  }

  Sentence add(SentenceWord word) => Sentence([...words, word]);

  Sentence removeLast() =>
      words.isEmpty ? this : Sentence(words.sublist(0, words.length - 1));

  Sentence clear() => const Sentence.empty();

  @override
  bool operator ==(Object other) =>
      other is Sentence &&
      other.words.length == words.length &&
      _listEquals(other.words, words);

  @override
  int get hashCode => Object.hashAll(words);

  @override
  String toString() => 'Sentence("$displayText")';

  static bool _listEquals(List<SentenceWord> a, List<SentenceWord> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
