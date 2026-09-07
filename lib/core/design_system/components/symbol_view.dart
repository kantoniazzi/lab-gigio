/// Renderiza o pictograma de um botão, seja ele SVG do Mulberry ou glifo nativo.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gigio/core/design_system/tokens/gigio_tokens.dart';
import 'package:gigio/core/symbols/symbol_catalog.dart';

class SymbolView extends StatelessWidget {
  const SymbolView({required this.symbolId, this.fallbackLabel, super.key});

  final String symbolId;

  /// Usado como rótulo de acessibilidade e quando o símbolo não resolve —
  /// melhor um botão só com texto do que um botão quebrado.
  final String? fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final source = SymbolCatalog.resolve(symbolId);

    return switch (source) {
      SvgSymbol(:final assetPath) => SvgPicture.asset(
          assetPath,
          fit: BoxFit.contain,
          semanticsLabel: fallbackLabel,
          placeholderBuilder: (_) => const SizedBox.shrink(),
        ),
      PoddCellSymbol(:final assetPath) => Image.asset(
          assetPath,
          fit: BoxFit.contain,
          semanticLabel: fallbackLabel,
          filterQuality: FilterQuality.medium,
        ),
      IconSymbol(:final icon) => LayoutBuilder(
          builder: (context, constraints) => Icon(
            icon,
            size: constraints.biggest.shortestSide * 0.75,
            color: GigioColors.textOnAccent,
            semanticLabel: fallbackLabel,
          ),
        ),
      null => const SizedBox.shrink(),
    };
  }
}
