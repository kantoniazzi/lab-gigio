// Descobre a geometria da grade PODD a partir de uma página renderizada em PGM.
//
// O fundo da página é cinza e os cartões são brancos com borda preta. Projetando
// a quantidade de pixels claros por coluna e por linha, as faixas de cartão
// aparecem como platôs — daí saem as fronteiras exatas, sem estimativa visual.
//
// Uso: dart run tool/analyze_podd_geometry.dart <arquivo.pgm>

import 'dart:io';

class Pgm {
  Pgm(this.width, this.height, this.pixels);
  final int width;
  final int height;
  final List<int> pixels;

  int at(int x, int y) => pixels[y * width + x];

  static Pgm parse(File file) {
    final bytes = file.readAsBytesSync();
    var pos = 0;

    String token() {
      while (pos < bytes.length && _isSpace(bytes[pos])) {
        pos++;
      }
      if (bytes[pos] == 0x23) {
        while (bytes[pos] != 0x0A) {
          pos++;
        }
        return token();
      }
      final start = pos;
      while (pos < bytes.length && !_isSpace(bytes[pos])) {
        pos++;
      }
      return String.fromCharCodes(bytes.sublist(start, pos));
    }

    final magic = token();
    if (magic != 'P5') throw FormatException('Esperava PGM binário (P5), veio $magic');
    final width = int.parse(token());
    final height = int.parse(token());
    token(); // maxval
    pos++; // único whitespace após o cabeçalho

    return Pgm(width, height, bytes.sublist(pos, pos + width * height));
  }

  static bool _isSpace(int b) => b == 0x20 || b == 0x0A || b == 0x0D || b == 0x09;
}

/// Faixas contíguas onde [values] fica acima de [threshold].
List<(int, int)> runs(List<double> values, double threshold, int minLength) {
  final result = <(int, int)>[];
  int? start;
  for (var i = 0; i < values.length; i++) {
    if (values[i] > threshold) {
      start ??= i;
    } else if (start != null) {
      if (i - start >= minLength) result.add((start, i - 1));
      start = null;
    }
  }
  if (start != null && values.length - start >= minLength) {
    result.add((start, values.length - 1));
  }
  return result;
}

void main(List<String> args) {
  final pgm = Pgm.parse(File(args.first));
  stdout.writeln('Imagem: ${pgm.width} x ${pgm.height}');

  // Valor modal = cor do fundo cinza da página.
  final histogram = List<int>.filled(256, 0);
  for (final p in pgm.pixels) {
    histogram[p]++;
  }
  var bg = 0;
  for (var v = 1; v < 256; v++) {
    if (histogram[v] > histogram[bg]) bg = v;
  }
  stdout.writeln('Fundo (valor modal): $bg');

  bool isBg(int v) => (v - bg).abs() <= 6;

  // Calhas: colunas/linhas quase inteiramente de fundo. Detectar o vazio é bem
  // mais robusto que detectar o cartão, porque o interior do cartão tem desenho.
  final colBg = List<double>.filled(pgm.width, 0);
  for (var x = 0; x < pgm.width; x++) {
    var count = 0;
    for (var y = 0; y < pgm.height; y++) {
      if (isBg(pgm.at(x, y))) count++;
    }
    colBg[x] = count / pgm.height;
  }
  final rowBg = List<double>.filled(pgm.height, 0);
  for (var y = 0; y < pgm.height; y++) {
    var count = 0;
    for (var x = 0; x < pgm.width; x++) {
      if (isBg(pgm.at(x, y))) count++;
    }
    rowBg[y] = count / pgm.width;
  }

  stdout.writeln('\n--- CALHAS verticais (>92% fundo) => separam colunas ---');
  for (final (a, b) in runs(colBg, 0.92, 5)) {
    stdout.writeln('  x $a..$b  (largura ${b - a + 1})');
  }
  stdout.writeln('\n--- CALHAS horizontais (>92% fundo) => separam linhas ---');
  for (final (a, b) in runs(rowBg, 0.92, 5)) {
    stdout.writeln('  y $a..$b  (altura ${b - a + 1})');
  }
}
