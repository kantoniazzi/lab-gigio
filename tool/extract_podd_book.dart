// Extrai as células do livro PODD da Gigi para assets endereçados por conteúdo.
//
// Uso:
//   dart run tool/extract_podd_book.dart <caminho-do-pdf> <primeira> <ultima>
//
// Cada célula vira um PNG identificado pelo **SHA-256 do próprio conteúdo**, e
// não por um nome. Isso dá desduplicação automática — "ooops" e "voltar para
// página 1" aparecem em toda página do livro e são armazenados uma única vez —
// e prepara o terreno para sincronização em nuvem incremental no futuro, sem
// migração de dados.
//
// O PDF NÃO é dependência de build: rodamos isto uma vez e versionamos o
// resultado, mantendo a compilação offline e auditável no diff.
//
// A ferramenta produz apenas **geometria e imagem**. A semântica de cada botão
// (rótulo, fala, ação, destino) é transcrita à mão a partir das páginas
// renderizadas — mais confiável que OCR nesta fonte, e é justamente onde um
// erro sairia caro.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'podd_geometry.dart';

/// Layout da página PODD padrão: 4 colunas de grade + 1 coluna lateral,
/// 3 linhas de grade + 1 faixa de abas. Detectar 5x4 significa página padrão;
/// qualquer outra proporção é uma página de lista (comida, músicas, vídeos),
/// que tem grade densa própria.
const _standardColumns = 5;
const _standardRows = 4;

class Cell {
  Cell({required this.slot, required this.hash, required this.file});

  /// `r0c2` para a grade, `s1` para a coluna lateral.
  final String slot;
  final String hash;
  final String file;
}

Future<void> main(List<String> args) async {
  if (args.length < 3) {
    stderr.writeln('Uso: dart run tool/extract_podd_book.dart <pdf> <primeira> <ultima>');
    exit(64);
  }

  final pdf = args[0];
  final first = int.parse(args[1]);
  final last = int.parse(args[2]);

  final work = Directory.systemTemp.createTempSync('podd_');
  final outDir = Directory('assets/podd')..createSync(recursive: true);

  stdout.writeln('Renderizando páginas $first..$last a 300 dpi...');
  final render = await Process.run('pdftoppm', [
    '-r', '300', '-png', '-f', '$first', '-l', '$last', pdf, '${work.path}/pg',
  ]);
  if (render.exitCode != 0) {
    stderr.writeln('pdftoppm falhou: ${render.stderr}');
    exit(70);
  }

  final pages = <String, List<Cell>>{};
  final layouts = <String, String>{};
  final seenHashes = <String>{};
  var cropCount = 0;

  for (var page = first; page <= last; page++) {
    final source = _findRendered(work, page);
    if (source == null) {
      stderr.writeln('  página $page: imagem não encontrada, pulando');
      continue;
    }

    // Geometria medida nesta página, não assumida. O livro mistura a página
    // PODD padrão com páginas de lista de grade bem mais densa.
    final pgm = await _renderPgm(pdf, page, work);
    if (pgm == null) {
      stderr.writeln('  página $page: não foi possível medir a grade, pulando');
      continue;
    }
    final grid = detectGrid(pgm);
    final size = await _pixelSize(source);

    final isStandard = grid.columns.length == _standardColumns &&
        grid.rows.length == _standardRows;
    final cells = <Cell>[];

    Future<void> crop(String slot, (int, int) xs, (int, int) ys) async {
      final left = (xs.$1 / grid.width * size.$1).round();
      final right = (xs.$2 / grid.width * size.$1).round();
      final top = (ys.$1 / grid.height * size.$2).round();
      final bottom = (ys.$2 / grid.height * size.$2).round();
      if (right <= left || bottom <= top) return;

      final temp = '${work.path}/crop_${page}_$slot.png';

      // O sips aplica --resampleWidth ANTES do recorte quando os dois vêm na
      // mesma invocação, o que fazia todos os offsets caírem fora da imagem já
      // reduzida e produzia recortes errados (símbolo trocado no botão).
      // Recortar e redimensionar precisam ser duas chamadas separadas.
      final cropped = await Process.run('sips', [
        '-c', '${bottom - top}', '${right - left}',
        '--cropOffset', '$top', '$left',
        source.path, '--out', temp,
      ]);
      if (cropped.exitCode != 0) return;

      final resized = await Process.run(
        'sips',
        ['--resampleWidth', '420', temp, '--out', temp],
      );
      if (resized.exitCode != 0) return;

      final bytes = File(temp).readAsBytesSync();
      final hash = sha256.convert(bytes).toString().substring(0, 16);
      final target = File('${outDir.path}/$hash.png');
      if (seenHashes.add(hash)) target.writeAsBytesSync(bytes);

      cells.add(Cell(slot: slot, hash: hash, file: '$hash.png'));
      cropCount++;
    }

    if (isStandard) {
      // Últimas faixas são a coluna lateral e a tira de abas; a grade útil é o
      // que vem antes delas.
      for (var r = 0; r < grid.rows.length - 1; r++) {
        for (var c = 0; c < grid.columns.length - 1; c++) {
          await crop('r${r}c$c', grid.columns[c], grid.rows[r]);
        }
      }
      final sidebarColumn = grid.columns.last;
      for (var r = 0; r < grid.rows.length - 1; r++) {
        await crop('s$r', sidebarColumn, grid.rows[r]);
      }
    } else {
      for (var r = 0; r < grid.rows.length; r++) {
        for (var c = 0; c < grid.columns.length; c++) {
          await crop('r${r}c$c', grid.columns[c], grid.rows[r]);
        }
      }
    }

    layouts['$page'] = isStandard
        ? 'padrao'
        : '${grid.columns.length}x${grid.rows.length}';

    pages['$page'] = cells;
    stdout.writeln('  página $page: ${cells.length} células (${layouts['$page']})');
  }

  // Mapa geometria→hash, insumo para a transcrição manual da semântica.
  File('tool/podd_cells.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'layouts': layouts,
      'cells': {
        for (final entry in pages.entries)
          entry.key: {for (final c in entry.value) c.slot: c.hash},
      },
    }),
  );

  final ids = seenHashes.toList()..sort();
  final buffer = StringBuffer()
    ..writeln('// GERADO POR tool/extract_podd_book.dart — NÃO EDITE À MÃO.')
    ..writeln('//')
    ..writeln('// Células do livro PODD da Gigi, identificadas pelo SHA-256 do')
    ..writeln('// próprio conteúdo. Pictogramas PCS (Tobii Dynavox/Boardmaker) e')
    ..writeln('// estrutura PODD (Gayle Porter / CPEC): uso pessoal, material da')
    ..writeln('// própria família. NÃO redistribuível comercialmente.')
    ..writeln('library;')
    ..writeln()
    ..writeln('const Set<String> kPoddCellIds = {');
  for (final id in ids) {
    buffer.writeln("  '$id',");
  }
  buffer.writeln('};');
  File('lib/core/symbols/podd_manifest.g.dart').writeAsStringSync(buffer.toString());

  work.deleteSync(recursive: true);

  stdout
    ..writeln()
    ..writeln('$cropCount recortes → ${ids.length} imagens únicas '
        '(${(100 - ids.length / cropCount * 100).toStringAsFixed(0)}% desduplicado)')
    ..writeln('Mapa de células: tool/podd_cells.json');
}

/// Renderiza a página em PGM de baixa resolução, insumo da medição da grade.
Future<File?> _renderPgm(String pdf, int page, Directory work) async {
  final prefix = '${work.path}/geo_$page';
  final result = await Process.run('pdftoppm', [
    '-gray', '-r', '100', '-f', '$page', '-l', '$page', pdf, prefix,
  ]);
  if (result.exitCode != 0) return null;
  for (final file in work.listSync().whereType<File>()) {
    final name = file.uri.pathSegments.last;
    if (name.startsWith("geo_$page-") && name.endsWith('.pgm')) return file;
  }
  return null;
}

File? _findRendered(Directory dir, int page) {
  for (final file in dir.listSync().whereType<File>()) {
    final name = file.uri.pathSegments.last;
    if (!name.startsWith('pg-') || !name.endsWith('.png')) continue;
    final digits = name.substring(3, name.length - 4);
    if (int.tryParse(digits) == page) return file;
  }
  return null;
}

Future<(int, int)> _pixelSize(File file) async {
  final result = await Process.run(
    'sips',
    ['-g', 'pixelWidth', '-g', 'pixelHeight', file.path],
  );
  final output = result.stdout.toString();
  int grab(String key) =>
      int.parse(RegExp('$key:\\s*(\\d+)').firstMatch(output)!.group(1)!);
  return (grab('pixelWidth'), grab('pixelHeight'));
}
