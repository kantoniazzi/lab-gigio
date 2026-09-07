/// O board completo e suas páginas.
///
/// Um board é um *documento*: a tela inteira é dado, não código. É isto que
/// permite que o editor de boards seja apenas outra UI sobre o mesmo modelo
/// que o renderizador consome, sem caminho paralelo.
library;

import 'package:gigio/core/errors/app_error.dart';
import 'package:gigio/core/result/result.dart';
import 'package:gigio/domain/models/aac_button.dart';
import 'package:gigio/domain/models/button_action.dart';

/// Versão do formato de arquivo. Incrementar ao fazer mudança incompatível,
/// para que uma versão futura do app saiba migrar (ou recusar) o board.
const int kBoardSchemaVersion = 2;

class BoardPage {
  const BoardPage({
    required this.id,
    required this.name,
    required this.rows,
    required this.columns,
    required this.buttons,
    this.sidebar = const [],
  });

  final String id;
  final String name;
  final int rows;
  final int columns;
  final List<AacButton> buttons;

  /// Coluna fixa à direita da grade.
  ///
  /// No PODD ela carrega os comandos que precisam estar sempre no mesmo lugar —
  /// "voltar para página 1", "ooops" (reparo de comunicação) e o retorno à
  /// página-mãe da seção. Ficam fora da grade de propósito: a posição desses
  /// três é constante em todo o livro, e é isso que os torna confiáveis.
  ///
  /// A `row` de cada botão indica a posição na coluna; a `column` é ignorada.
  final List<AacButton> sidebar;

  int get capacity => rows * columns;

  AacButton? buttonAt(int row, int column) {
    for (final button in buttons) {
      if (button.row == row && button.column == column) return button;
    }
    return null;
  }

  BoardPage copyWith({
    String? name,
    int? rows,
    int? columns,
    List<AacButton>? buttons,
    List<AacButton>? sidebar,
  }) =>
      BoardPage(
        id: id,
        name: name ?? this.name,
        rows: rows ?? this.rows,
        columns: columns ?? this.columns,
        buttons: buttons ?? this.buttons,
        sidebar: sidebar ?? this.sidebar,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'rows': rows,
        'columns': columns,
        'buttons': buttons.map((b) => b.toJson()).toList(),
        if (sidebar.isNotEmpty)
          'sidebar': sidebar.map((b) => b.toJson()).toList(),
      };

  static Result<BoardPage> fromJson(Map<String, Object?> json) {
    final id = json['id'];
    if (id is! String || id.trim().isEmpty) {
      return const Err(BoardValidationError('Página sem "id" válido.'));
    }

    final name = json['name'];
    if (name is! String) {
      return Err(BoardValidationError('Página "$id" sem "name" válido.', field: 'pages.$id'));
    }

    final rows = json['rows'];
    final columns = json['columns'];
    if (rows is! int || columns is! int) {
      return Err(BoardValidationError(
        'Página "$id" precisa de "rows" e "columns" inteiros.',
        field: 'pages.$id',
      ));
    }
    // Limite superior evita que um board malicioso ou corrompido tente alocar
    // uma grade gigantesca e derrube o app por falta de memória.
    if (rows < 1 || columns < 1 || rows > 12 || columns > 12) {
      return Err(BoardValidationError(
        'A grade da página "$id" é ${rows}x$columns; o suportado vai de 1x1 a 12x12.',
        field: 'pages.$id',
      ));
    }

    final rawButtons = json['buttons'];
    if (rawButtons is! List) {
      return Err(BoardValidationError(
        'Página "$id" precisa de uma lista "buttons".',
        field: 'pages.$id',
      ));
    }

    final buttons = <AacButton>[];
    final seenIds = <String>{};
    final occupied = <String>{};

    for (var i = 0; i < rawButtons.length; i++) {
      final raw = rawButtons[i];
      if (raw is! Map<String, Object?>) {
        return Err(BoardValidationError(
          'O item $i de "buttons" da página "$id" não é um objeto.',
          field: 'pages.$id.buttons[$i]',
        ));
      }

      final parsed = AacButton.fromJson(
        raw,
        rows: rows,
        columns: columns,
        field: 'pages.$id.buttons[$i]',
      );
      switch (parsed) {
        case Err(:final error):
          return Err(error);
        case Ok(:final value):
          if (!seenIds.add(value.id)) {
            return Err(BoardValidationError(
              'A página "$id" tem dois botões com o id "${value.id}".',
              field: 'pages.$id.buttons[$i]',
            ));
          }
          final slot = '${value.row}:${value.column}';
          if (!occupied.add(slot)) {
            return Err(BoardValidationError(
              'A página "$id" tem dois botões na posição '
              '(${value.row}, ${value.column}).',
              field: 'pages.$id.buttons[$i]',
            ));
          }
          buttons.add(value);
      }
    }

    final sidebar = <AacButton>[];
    final rawSidebar = json['sidebar'];
    if (rawSidebar != null) {
      if (rawSidebar is! List) {
        return Err(BoardValidationError(
          'O campo "sidebar" da página "$id" precisa ser uma lista.',
          field: 'pages.$id',
        ));
      }
      for (var i = 0; i < rawSidebar.length; i++) {
        final raw = rawSidebar[i];
        if (raw is! Map<String, Object?>) {
          return Err(BoardValidationError(
            'O item $i de "sidebar" da página "$id" não é um objeto.',
            field: 'pages.$id.sidebar[$i]',
          ));
        }
        // A coluna lateral é uma faixa vertical de uma coluna só; validamos a
        // linha contra o número de linhas da página e fixamos a coluna em 0.
        final parsed = AacButton.fromJson(
          {...raw, 'position': [(raw['position']! as List)[0], 0]},
          rows: rows,
          columns: 1,
          field: 'pages.$id.sidebar[$i]',
        );
        switch (parsed) {
          case Err(:final error):
            return Err(error);
          case Ok(:final value):
            sidebar.add(value);
        }
      }
    }

    return Ok(BoardPage(
      id: id,
      name: name,
      rows: rows,
      columns: columns,
      buttons: buttons,
      sidebar: sidebar,
    ));
  }
}

class Board {
  const Board({
    required this.id,
    required this.name,
    required this.homePageId,
    required this.pages,
    this.schemaVersion = kBoardSchemaVersion,
  });

  final String id;
  final String name;
  final String homePageId;
  final Map<String, BoardPage> pages;
  final int schemaVersion;

  BoardPage? page(String id) => pages[id];
  BoardPage get homePage => pages[homePageId]!;

  Board copyWith({String? name, String? homePageId, Map<String, BoardPage>? pages}) => Board(
        id: id,
        name: name ?? this.name,
        homePageId: homePageId ?? this.homePageId,
        pages: pages ?? this.pages,
        schemaVersion: schemaVersion,
      );

  /// Substitui uma página, devolvendo um novo board (o modelo é imutável).
  Board withPage(BoardPage page) => copyWith(pages: {...pages, page.id: page});

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'name': name,
        'homePageId': homePageId,
        'pages': pages.values.map((p) => p.toJson()).toList(),
      };

  static Result<Board> fromJson(Map<String, Object?> json) {
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion is! int) {
      return const Err(BoardValidationError(
        'O arquivo não tem "schemaVersion" — pode não ser um board do Gigio.',
      ));
    }
    if (schemaVersion > kBoardSchemaVersion) {
      return Err(BoardValidationError(
        'Este board foi criado na versão $schemaVersion do formato, mas este '
        'Gigio entende até a $kBoardSchemaVersion. Atualize o aplicativo.',
      ));
    }

    final id = json['id'];
    final name = json['name'];
    final homePageId = json['homePageId'];
    if (id is! String || id.trim().isEmpty) {
      return const Err(BoardValidationError('Board sem "id" válido.'));
    }
    if (name is! String) {
      return const Err(BoardValidationError('Board sem "name" válido.'));
    }
    if (homePageId is! String || homePageId.trim().isEmpty) {
      return const Err(BoardValidationError('Board sem "homePageId" válido.'));
    }

    final rawPages = json['pages'];
    if (rawPages is! List || rawPages.isEmpty) {
      return const Err(BoardValidationError('O board precisa de ao menos uma página.'));
    }

    final pages = <String, BoardPage>{};
    for (final raw in rawPages) {
      if (raw is! Map<String, Object?>) {
        return const Err(BoardValidationError('Um item de "pages" não é um objeto.'));
      }
      final parsed = BoardPage.fromJson(raw);
      switch (parsed) {
        case Err(:final error):
          return Err(error);
        case Ok(:final value):
          if (pages.containsKey(value.id)) {
            return Err(BoardValidationError('Há duas páginas com o id "${value.id}".'));
          }
          pages[value.id] = value;
      }
    }

    if (!pages.containsKey(homePageId)) {
      return Err(BoardValidationError(
        'A página inicial "$homePageId" não existe no board.',
      ));
    }

    // Integridade referencial: um botão que navega para uma página inexistente
    // seria, para a criança, um botão que simplesmente não funciona. É melhor
    // recusar o board na importação do que descobrir isso no meio de uma
    // tentativa de comunicação.
    for (final page in pages.values) {
      for (final button in [...page.buttons, ...page.sidebar]) {
        final action = button.action;
        if (action is NavigateAction && !pages.containsKey(action.targetPageId)) {
          return Err(BoardValidationError(
            'O botão "${button.label}" da página "${page.id}" aponta para a '
            'página "${action.targetPageId}", que não existe.',
            field: 'pages.${page.id}.buttons.${button.id}',
          ));
        }
      }
    }

    return Ok(Board(
      id: id,
      name: name,
      homePageId: homePageId,
      pages: pages,
      schemaVersion: schemaVersion,
    ));
  }
}
