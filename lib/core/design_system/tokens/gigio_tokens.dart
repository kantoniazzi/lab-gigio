/// Design tokens do Gigio.
///
/// Nenhuma cor, espaçamento ou dimensão deve ser escrita diretamente num
/// widget. Tudo passa por aqui, para que trocar o tema — alto contraste, tema
/// escuro, tamanhos maiores para uma criança com baixa visão — seja mudar um
/// arquivo, e não caçar constantes espalhadas pela UI.
library;

import 'package:flutter/widgets.dart';
import 'package:gigio/domain/models/word_class.dart';

/// Cores da Fitzgerald Key, a convenção de CAA que colore os símbolos por
/// classe gramatical.
///
/// Os tons foram escurecidos em relação às cores puras tradicionais para que o
/// texto preto sobre eles alcance contraste WCAG AA (≥ 4.5:1) — a versão
/// clássica em amarelo saturado falha esse critério.
abstract final class GigioColors {
  static const pronoun = Color(0xFFF2C94C);
  static const verb = Color(0xFF7DC383);
  static const adjective = Color(0xFF7FB3D5);
  static const noun = Color(0xFFF0A868);
  static const social = Color(0xFFE8A0BF);
  static const preposition = Color(0xFFE8E4DC);
  static const question = Color(0xFFB39DDB);
  static const negation = Color(0xFFE88B8B);
  static const category = Color(0xFFCFD8DC);
  static const system = Color(0xFF90A4AE);

  static const background = Color(0xFFF7F7F5);
  static const surface = Color(0xFFFFFFFF);
  static const sentenceBarBackground = Color(0xFFFFFFFF);
  static const border = Color(0xFFD4D4D0);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF5A5A5A);
  static const textOnAccent = Color(0xFF1A1A1A);

  static const accent = Color(0xFF2E7D8F);
  static const danger = Color(0xFFC0392B);
  static const editModeAccent = Color(0xFF7B4B94);

  /// Cor de fundo do botão para cada classe gramatical.
  static Color forWordClass(WordClass wordClass) => switch (wordClass) {
        WordClass.pronoun => pronoun,
        WordClass.verb => verb,
        WordClass.adjective => adjective,
        WordClass.noun => noun,
        WordClass.social => social,
        WordClass.preposition => preposition,
        WordClass.question => question,
        WordClass.negation => negation,
        WordClass.category => category,
        WordClass.system => system,
      };
}

abstract final class GigioSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class GigioRadius {
  static const double button = 12;
  static const double card = 16;
  static const double container = 20;
}

abstract final class GigioTypography {
  /// Rótulo do botão. O tamanho real é calculado pelo `LayoutEngine` conforme o
  /// tamanho da célula; este é o piso.
  static const double buttonLabelMin = 12;
  static const double buttonLabelMax = 28;

  static const TextStyle sentenceBar = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: GigioColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle heading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: GigioColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: GigioColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    color: GigioColors.textSecondary,
  );
}

abstract final class GigioAccessibility {
  /// Alvo mínimo de toque, em pontos lógicos.
  ///
  /// 44pt é o mínimo das Human Interface Guidelines da Apple. Para uma criança
  /// com dificuldade motora fina, quanto maior melhor — por isso o
  /// `LayoutEngine` sempre expande a célula até o espaço disponível em vez de
  /// respeitar apenas o mínimo.
  static const double minTouchTarget = 44;

  /// Tempo de pressão longa para abrir o modo de edição.
  ///
  /// Deliberadamente longo: é o primeiro dos dois obstáculos que impedem a
  /// criança de entrar no editor por acidente e desconfigurar o próprio board.
  static const Duration editUnlockHold = Duration(milliseconds: 2000);
}

abstract final class GigioMotion {
  /// Curto de propósito: um retorno tátil lento atrapalha quem se comunica
  /// tocando símbolos em sequência rápida.
  static const Duration tap = Duration(milliseconds: 90);
  static const Duration transition = Duration(milliseconds: 180);
}
