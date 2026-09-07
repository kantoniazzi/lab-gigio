// Copia os pictogramas Mulberry usados pelo Gigio para `assets/symbols/`,
// renomeando-os para ids em português, e gera o manifesto Dart.
//
// Uso:
//   dart run tool/curate_symbols.dart <caminho-do-repo-mulberry>
//
// O repositório Mulberry NÃO é dependência de build: rodamos isto uma vez e
// versionamos o resultado. Assim o app não depende de rede para compilar, e o
// conjunto de símbolos embarcados é auditável no próprio diff.
//
// Pictogramas: Mulberry Symbols, © Steve Lee, CC BY-SA 2.0 UK.

import 'dart:io';

/// id em português → nome do arquivo Mulberry (sem `.svg`).
///
/// Palavras de função que o Mulberry não cobre (sim, não, obrigado, parar,
/// gostar, eu, você...) não aparecem aqui: são resolvidas por glifos nativos
/// em `SymbolCatalog._builtinIcons`.
const Map<String, String> kSymbolMapping = {
  // Pessoas
  'mamae': 'mum_parent',
  'papai': 'dad_parent',

  // Verbos nucleares
  'querer': 'want_,_to',
  'ir': 'go_,_to',
  'comer': 'eat_,_to',
  'beber': 'drink_,_to',
  'brincar': 'play_,_to',
  'ajudar': 'help_,_to',
  'dormir': 'sleep_on_side_,_to',
  'ver': 'look_,_to',
  'abrir': 'open_,_to',
  'dar': 'give_,_to',
  'sentar': 'sit_,_to',
  'abracar': 'hug_,_to',

  // Descritivos e estados
  'mais': 'more',
  'acabou': 'finish',
  'quente': 'hot',
  'fome': 'hungry',
  'sede': 'thirsty',
  'feliz': 'happy_lady',
  'triste': 'sad_lady',
  'bravo': 'angry_lady',

  // Substantivos
  'agua': 'water',
  'comida': 'food',
  'leite': 'milk',
  'pao': 'bread',
  'banana': 'banana',
  'maca': 'apple',
  'banheiro': 'toilet',
  'casa': 'house',
  'escola': 'school',
  'bola': 'ball',
  'musica': 'music',
  'carro': 'car',
  'cachorro': 'dog',
  'gato': 'cat',
  'tv': 'childrens_tv',
  'banho': 'bath',
  'roupa': 'clothes_generic',
  'fora': 'outside',
  'brinquedo': 'toy_box',

  // Perguntas
  'o-que': 'what',
  'onde': 'where',
  'quem': 'who',
  'quando': 'when',
  'por-que': 'why',
};

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Uso: dart run tool/curate_symbols.dart <repo-mulberry>');
    exit(64);
  }

  final sourceDir = Directory('${args.first}/EN');
  if (!sourceDir.existsSync()) {
    stderr.writeln('Diretório não encontrado: ${sourceDir.path}');
    exit(66);
  }

  final outDir = Directory('assets/symbols')..createSync(recursive: true);

  final copied = <String>[];
  final missing = <String>[];

  for (final entry in kSymbolMapping.entries) {
    final source = File('${sourceDir.path}/${entry.value}.svg');
    if (!source.existsSync()) {
      missing.add('${entry.key} → ${entry.value}.svg');
      continue;
    }
    source.copySync('${outDir.path}/${entry.key}.svg');
    copied.add(entry.key);
  }

  copied.sort();

  final buffer = StringBuffer()
    ..writeln('// GERADO POR tool/curate_symbols.dart — NÃO EDITE À MÃO.')
    ..writeln('//')
    ..writeln('// Pictogramas: Mulberry Symbols, © Steve Lee,')
    ..writeln('// licenciados sob CC BY-SA 2.0 UK — https://mulberrysymbols.org')
    ..writeln('library;')
    ..writeln()
    ..writeln('/// Ids dos símbolos SVG realmente embarcados em assets/symbols/.')
    ..writeln('const Set<String> kBundledSymbolIds = {');
  for (final id in copied) {
    buffer.writeln("  '$id',");
  }
  buffer.writeln('};');

  File('lib/core/symbols/symbol_manifest.g.dart')
      .writeAsStringSync(buffer.toString());

  stdout.writeln('${copied.length} símbolos copiados para assets/symbols/');
  if (missing.isNotEmpty) {
    stdout.writeln('\n${missing.length} não encontrados no Mulberry:');
    for (final m in missing) {
      stdout.writeln('  - $m');
    }
  }
}
