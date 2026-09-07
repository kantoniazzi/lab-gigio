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

/// Geometria calibrada em `tool/analyze_podd_geometry.dart`, detectando as
/// calhas de fundo cinza entre os cartões. Expressa em fração da página para
/// ficar independente da resolução de renderização.
const _refWidth = 1138.0;
const _refHeight = 799.0;

const _columns = [(9, 199), (249, 445), (516, 716), (768, 972)];
const _rows = [(34, 225), (284, 476), (532, 720)];
const _sidebarColumn = (1019, 1129);

/// A coluna lateral tem 3 posições que acompanham as mesmas faixas verticais
/// das linhas da grade principal.
const _sidebarRows = _rows;

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
  final seenHashes = <String>{};
  var cropCount = 0;

  for (var page = first; page <= last; page++) {
    final source = _findRendered(work, page);
    if (source == null) {
      stderr.writeln('  página $page: imagem não encontrada, pulando');
      continue;
    }

    final size = await _pixelSize(source);
    final cells = <Cell>[];

    Future<void> crop(String slot, (int, int) xs, (int, int) ys) async {
      final left = (xs.$1 / _refWidth * size.$1).round();
      final right = (xs.$2 / _refWidth * size.$1).round();
      final top = (ys.$1 / _refHeight * size.$2).round();
      final bottom = (ys.$2 / _refHeight * size.$2).round();

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

      // Reduz para o tamanho em que o cartão é de fato exibido; 300 dpi por
      // célula inflaria o app sem ganho visual.
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

    for (var r = 0; r < _rows.length; r++) {
      for (var c = 0; c < _columns.length; c++) {
        await crop('r${r}c$c', _columns[c], _rows[r]);
      }
    }
    for (var s = 0; s < _sidebarRows.length; s++) {
      await crop('s$s', _sidebarColumn, _sidebarRows[s]);
    }

    pages['$page'] = cells;
    stdout.writeln('  página $page: ${cells.length} células');
  }

  // Mapa geometria→hash, insumo para a transcrição manual da semântica.
  File('tool/podd_cells.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      for (final entry in pages.entries)
        entry.key: {for (final c in entry.value) c.slot: c.hash},
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
