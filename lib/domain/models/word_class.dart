/// Classe gramatical de um botão, usada para a codificação de cor.
///
/// Segue a **Fitzgerald Key**, a convenção consagrada em CAA que colore os
/// símbolos por função gramatical. Ela existe por uma razão terapêutica
/// concreta: a cor dá à criança uma pista de localização antes mesmo da
/// leitura, e sustenta o aprendizado da estrutura da frase.
///
/// A cor concreta de cada classe vive no design system (`core/design_system`),
/// não aqui — o domínio define o significado, a apresentação define o pixel.
library;

enum WordClass {
  /// Pronomes e pessoas — amarelo. Ex.: eu, você, mamãe.
  pronoun,

  /// Verbos — verde. Ex.: quero, ir, comer.
  verb,

  /// Adjetivos e descritivos — azul. Ex.: grande, feliz, quente.
  adjective,

  /// Substantivos — laranja. Ex.: água, bola, casa.
  noun,

  /// Expressões sociais — rosa. Ex.: oi, obrigado, por favor.
  social,

  /// Preposições e localização — branco. Ex.: em, dentro, embaixo.
  preposition,

  /// Perguntas — roxo. Ex.: quem, onde, quando.
  question,

  /// Negação e afirmação — vermelho. Ex.: não, pare, acabou.
  negation,

  /// Categorias de navegação — cinza. Ex.: Comida, Brincar.
  category,

  /// Controles do próprio app — cinza escuro. Ex.: falar, limpar, apagar.
  system;

  static WordClass fromJson(String? value) => switch (value) {
        'pronoun' => WordClass.pronoun,
        'verb' => WordClass.verb,
        'adjective' => WordClass.adjective,
        'noun' => WordClass.noun,
        'social' => WordClass.social,
        'preposition' => WordClass.preposition,
        'question' => WordClass.question,
        'negation' => WordClass.negation,
        'category' => WordClass.category,
        'system' => WordClass.system,
        // Um board de versão futura pode trazer uma classe que ainda não
        // conhecemos. Cair para `noun` degrada a cor, mas mantém o botão
        // funcional — aqui a comunicação vale mais que a fidelidade visual.
        _ => WordClass.noun,
      };

  String toJson() => name;
}
