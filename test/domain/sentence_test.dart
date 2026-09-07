import 'package:flutter_test/flutter_test.dart';
import 'package:gigio/domain/models/sentence.dart';

void main() {
  group('Sentence', () {
    test('começa vazia', () {
      const sentence = Sentence.empty();
      expect(sentence.isEmpty, isTrue);
      expect(sentence.displayText, '');
      expect(sentence.spokenText, '');
    });

    test('monta "eu quero água" na ordem em que os botões foram tocados', () {
      final sentence = const Sentence.empty()
          .add(const SentenceWord(display: 'eu'))
          .add(const SentenceWord(display: 'quero'))
          .add(const SentenceWord(display: 'água'));

      expect(sentence.displayText, 'eu quero água');
      expect(sentence.length, 3);
    });

    test('capitaliza e pontua o texto falado', () {
      final sentence = const Sentence.empty()
          .add(const SentenceWord(display: 'eu'))
          .add(const SentenceWord(display: 'quero'))
          .add(const SentenceWord(display: 'água'));

      // Sem isso os sintetizadores leem a frase com entonação de lista.
      expect(sentence.spokenText, 'Eu quero água.');
    });

    test('não duplica pontuação quando a palavra já termina em pontuação', () {
      final sentence =
          const Sentence.empty().add(const SentenceWord(display: 'me ajuda!'));
      expect(sentence.spokenText, 'Me ajuda!');
    });

    test('usa a forma falada quando ela difere da exibida', () {
      final sentence = const Sentence.empty().add(
        const SentenceWord(display: 'banheiro', spoken: 'preciso ir ao banheiro'),
      );

      expect(sentence.displayText, 'banheiro');
      expect(sentence.spokenText, 'Preciso ir ao banheiro.');
    });

    test('removeLast apaga a última palavra', () {
      final sentence = const Sentence.empty()
          .add(const SentenceWord(display: 'eu'))
          .add(const SentenceWord(display: 'quero'))
          .removeLast();

      expect(sentence.displayText, 'eu');
    });

    test('removeLast numa frase vazia não quebra', () {
      expect(const Sentence.empty().removeLast().isEmpty, isTrue);
    });

    test('clear esvazia a frase', () {
      final sentence =
          const Sentence.empty().add(const SentenceWord(display: 'eu')).clear();
      expect(sentence.isEmpty, isTrue);
    });

    test('é imutável — operar não altera a instância original', () {
      const original = Sentence.empty();
      original.add(const SentenceWord(display: 'eu'));
      expect(original.isEmpty, isTrue);
    });
  });
}
