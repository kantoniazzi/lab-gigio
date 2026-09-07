// Detecta a grade de uma página do livro a partir da imagem renderizada.
//
// O livro tem dois layouts: a página PODD padrão (4x3 + coluna lateral) e as
// páginas de lista (comida, músicas, vídeos), com grades densas de proporções
// variadas. Assumir 4x3 fixo picotava as listas, então a geometria é medida
// por página.
//
// O método é o mesmo calibrado em tool/analyze_podd_geometry.dart: detectar as
// CALHAS de fundo entre os cartões. Procurar o cartão falha, porque o interior
// dele é cheio de desenho escuro; procurar o vazio é um sinal limpo.

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
    bool isSpace(int b) => b == 0x20 || b == 0x0A || b == 0x0D || b == 0x09;

    String token() {
      while (pos < bytes.length && isSpace(bytes[pos])) {
        pos++;
      }
      if (bytes[pos] == 0x23) {
        while (bytes[pos] != 0x0A) {
          pos++;
        }
        return token();
      }
      final start = pos;
      while (pos < bytes.length && !isSpace(bytes[pos])) {
        pos++;
      }
      return String.fromCharCodes(bytes.sublist(start, pos));
    }

    if (token() != 'P5') throw const FormatException('Esperava PGM binário (P5)');
    final width = int.parse(token());
    final height = int.parse(token());
    token();
    pos++;
    return Pgm(width, height, bytes.sublist(pos, pos + width * height));
  }
}

/// Faixas de conteúdo (cartões), obtidas invertendo as calhas de fundo.
class Grid {
  Grid(this.columns, this.rows, this.width, this.height);
  final List<(int, int)> columns;
  final List<(int, int)> rows;
  final int width;
  final int height;
}

Grid detectGrid(File pgmFile) {
  final pgm = Pgm.parse(pgmFile);

  // O fundo é amostrado pela BORDA da página, não pelo valor modal do
  // documento inteiro. Em páginas onde os cartões brancos dominam a área, o
  // branco vira moda e o fundo cinza deixa de ser reconhecido — o que fazia
  // páginas padrão serem lidas como uma célula única.
  final border = <int>[];
  final marginX = (pgm.width * 0.005).round().clamp(1, 8);
  final marginY = (pgm.height * 0.005).round().clamp(1, 8);
  for (var x = 0; x < pgm.width; x++) {
    for (var m = 0; m < marginY; m++) {
      border..add(pgm.at(x, m))..add(pgm.at(x, pgm.height - 1 - m));
    }
  }
  for (var y = 0; y < pgm.height; y++) {
    for (var m = 0; m < marginX; m++) {
      border..add(pgm.at(m, y))..add(pgm.at(pgm.width - 1 - m, y));
    }
  }
  border.sort();
  final background = border[border.length ~/ 2];
  bool isBackground(int v) => (v - background).abs() <= 6;

  List<double> project(bool vertical) {
    final length = vertical ? pgm.width : pgm.height;
    final span = vertical ? pgm.height : pgm.width;
    return List<double>.generate(length, (i) {
      var count = 0;
      for (var j = 0; j < span; j++) {
        if (isBackground(vertical ? pgm.at(i, j) : pgm.at(j, i))) count++;
      }
      return count / span;
    });
  }

  /// Inverte as calhas: o que sobra entre elas são as faixas de cartão.
  List<(int, int)> bands(List<double> gutterScore, int minWidth) {
    final gutters = <(int, int)>[];
    int? start;
    for (var i = 0; i < gutterScore.length; i++) {
      if (gutterScore[i] > 0.92) {
        start ??= i;
      } else if (start != null) {
        if (i - start >= 4) gutters.add((start, i - 1));
        start = null;
      }
    }
    if (start != null) gutters.add((start, gutterScore.length - 1));

    final result = <(int, int)>[];
    var cursor = 0;
    for (final (a, b) in gutters) {
      if (a - cursor >= minWidth) result.add((cursor, a - 1));
      cursor = b + 1;
    }
    if (gutterScore.length - cursor >= minWidth) {
      result.add((cursor, gutterScore.length - 1));
    }
    return result;
  }

  // Piso proporcional: descarta bordas e filetes, mantendo células reais mesmo
  // numa lista densa de 7 colunas.
  return Grid(
    bands(project(true), (pgm.width * 0.04).round()),
    bands(project(false), (pgm.height * 0.05).round()),
    pgm.width,
    pgm.height,
  );
}
