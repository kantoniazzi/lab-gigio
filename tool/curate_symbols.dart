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

/// Converte classes CSS de um `<style>` em atributos de apresentação.
///
/// Muitos SVGs do Mulberry declaram as cores num bloco `<style>` com classes
/// (`.st0{fill:#fff}`). O `flutter_svg` **não interpreta CSS** — ele só lê
/// atributos de apresentação —, então esses arquivos renderizam como manchas
/// pretas sólidas, que num app de CAA significa um símbolo ilegível.
///
/// Aqui achatamos o CSS para dentro dos elementos, uma vez, na curadoria. É
/// preferível a fazer isso em tempo de execução: o custo é pago no build e o
/// resultado fica auditável no repositório.
String inlineCssClasses(String svg) {
  final styleBlocks = RegExp(r'<style[^>]*>(.*?)</style>', dotAll: true)
      .allMatches(svg)
      .map((m) => m.group(1)!)
      .join('\n');

  if (styleBlocks.trim().isEmpty) return svg;

  // Classe → propriedade → valor, respeitando a ordem das regras (a última
  // declaração da mesma propriedade vence, como na cascata do CSS).
  final classDecls = <String, Map<String, String>>{};

  for (final rule in styleBlocks.split('}')) {
    final parts = rule.split('{');
    if (parts.length != 2) continue;

    final selectors = parts[0]
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.startsWith('.'))
        .map((s) => s.substring(1));

    final decls = <String, String>{};
    for (final decl in parts[1].split(';')) {
      final kv = decl.split(':');
      if (kv.length != 2) continue;
      decls[kv[0].trim()] = kv[1].trim();
    }
    if (decls.isEmpty) continue;

    for (final selector in selectors) {
      (classDecls[selector] ??= <String, String>{}).addAll(decls);
    }
  }

  var result = svg.replaceAll(
    RegExp(r'<style[^>]*>.*?</style>', dotAll: true),
    '',
  );

  // Reescreve cada elemento que usa `class`, trocando-a pelos atributos.
  result = result.replaceAllMapped(
    RegExp(r'<(\w+)([^>]*?)(/?)>'),
    (match) {
      final tag = match.group(1)!;
      var attrs = match.group(2)!;
      final selfClose = match.group(3)!;

      final classMatch = RegExp(r'''\sclass\s*=\s*["']([^"']*)["']''').firstMatch(attrs);
      if (classMatch == null) return match.group(0)!;

      final merged = <String, String>{};
      for (final name in classMatch.group(1)!.split(RegExp(r'\s+'))) {
        final decls = classDecls[name.trim()];
        if (decls != null) merged.addAll(decls);
      }

      attrs = attrs.replaceRange(classMatch.start, classMatch.end, '');

      // O CSS tem precedência sobre atributos de apresentação, então qualquer
      // atributo homônimo pré-existente é substituído.
      for (final property in merged.keys) {
        attrs = attrs.replaceAll(
          RegExp('''\\s$property\\s*=\\s*["'][^"']*["']'''),
          '',
        );
      }

      final rendered =
          merged.entries.map((e) => '${e.key}="${e.value}"').join(' ');

      return '<$tag${attrs.trimRight()}'
          '${rendered.isEmpty ? '' : ' $rendered'}$selfClose>';
    },
  );

  return result;
}

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
    File('${outDir.path}/${entry.key}.svg')
        .writeAsStringSync(inlineCssClasses(source.readAsStringSync()));
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
