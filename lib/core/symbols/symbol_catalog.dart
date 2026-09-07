/// Catálogo de pictogramas.
///
/// Um board guarda apenas o *id* do símbolo, nunca um caminho de arquivo.
/// Este catálogo é a única porta entre id e asset, e é assim de propósito: um
/// board importado de fora não consegue apontar para um caminho arbitrário do
/// sistema de arquivos (*path traversal*), porque ids desconhecidos ou com
/// caracteres suspeitos simplesmente não resolvem.
///
/// O catálogo é híbrido por necessidade. O Mulberry cobre muito bem o
/// vocabulário concreto (água, cachorro, escola), mas **não possui** várias
/// palavras de função de altíssima frequência em CAA — sim, não, obrigado,
/// por favor, parar, gostar, eu, você. Para essas, usamos glifos nativos:
/// são palavras abstratas, que em CAA já são convencionalmente representadas
/// por símbolos simples, e cuja pista principal para a criança acaba sendo a
/// cor da Fitzgerald Key e a posição fixa na grade.
///
/// Pictogramas SVG: Mulberry Symbols, © Steve Lee, CC BY-SA 2.0 UK
/// https://mulberrysymbols.org
library;

import 'package:flutter/material.dart';
import 'package:gigio/core/symbols/symbol_manifest.g.dart';

/// De onde vem o desenho de um símbolo.
sealed class SymbolSource {
  const SymbolSource();
}

final class SvgSymbol extends SymbolSource {
  const SvgSymbol(this.assetPath);
  final String assetPath;
}

final class IconSymbol extends SymbolSource {
  const IconSymbol(this.icon);
  final IconData icon;
}

abstract final class SymbolCatalog {
  static const String _assetDir = 'assets/symbols';

  /// Glifos nativos para palavras de função que o Mulberry não cobre.
  static const Map<String, IconData> _builtinIcons = {
    'eu': Icons.person,
    'voce': Icons.person_outline,
    'nos': Icons.people,
    'sim': Icons.check_circle,
    'nao': Icons.cancel,
    'parar': Icons.pan_tool,
    'gostar': Icons.favorite,
    'nao-gostar': Icons.heart_broken,
    'obrigado': Icons.volunteer_activism,
    'por-favor': Icons.front_hand,
    'desculpa': Icons.sentiment_dissatisfied,
    'tchau': Icons.waving_hand,
    'cansado': Icons.bedtime,
    'dor': Icons.healing,
    'frio': Icons.ac_unit,
    'grande': Icons.zoom_out_map,
    'pequeno': Icons.zoom_in_map,
    'sentimentos': Icons.mood,
    'pessoas': Icons.groups,
    'lugares': Icons.place,
    'corpo': Icons.accessibility_new,
    'bebida': Icons.local_drink,
    // Controles do próprio app.
    'falar': Icons.volume_up,
    'apagar': Icons.backspace,
    'limpar': Icons.delete_sweep,
    'voltar': Icons.arrow_back,
    'inicio': Icons.home,
  };

  /// Apenas minúsculas, dígitos, hífen e sublinhado. Barra, ponto-ponto e til
  /// são rejeitados antes de virarem caminho.
  static final RegExp _safeId = RegExp(r'^[a-z0-9_-]{1,64}$');

  static bool isValidId(String id) => _safeId.hasMatch(id);

  /// Resolve o id para uma fonte de desenho, ou `null` se desconhecido.
  static SymbolSource? resolve(String symbolId) {
    if (!isValidId(symbolId)) return null;

    if (kBundledSymbolIds.contains(symbolId)) {
      return SvgSymbol('$_assetDir/$symbolId.svg');
    }
    final icon = _builtinIcons[symbolId];
    return icon == null ? null : IconSymbol(icon);
  }

  /// Todos os ids disponíveis, ordenados — usado pelo seletor do editor.
  static List<String> get sortedIds =>
      {...kBundledSymbolIds, ..._builtinIcons.keys}.toList()..sort();

  /// Busca por substring, com prefixo tendo prioridade.
  static List<String> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return sortedIds;

    return sortedIds.where((id) => id.contains(q)).toList()
      ..sort((a, b) {
        final aStarts = a.startsWith(q);
        final bStarts = b.startsWith(q);
        if (aStarts != bStarts) return aStarts ? -1 : 1;
        return a.compareTo(b);
      });
  }
}
