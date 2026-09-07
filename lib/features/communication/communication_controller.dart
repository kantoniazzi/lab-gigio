/// O núcleo de comunicação: botão → palavra → frase → voz.
///
/// Recebe uma ação (que é dado) e a executa. O `switch` sobre `ButtonAction` é
/// exaustivo: adicionar um tipo de ação novo quebra a compilação aqui, o que é
/// exatamente o que queremos — nenhum botão pode acabar sem comportamento.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigio/core/errors/app_error.dart';
import 'package:gigio/core/result/result.dart';
import 'package:gigio/data/board_repository.dart';
import 'package:gigio/domain/models/aac_button.dart';
import 'package:gigio/domain/models/board.dart';
import 'package:gigio/domain/models/button_action.dart';
import 'package:gigio/domain/models/sentence.dart';
import 'package:gigio/engines/speech/speech_provider.dart';

class CommunicationState {
  const CommunicationState({
    required this.board,
    required this.currentPageId,
    this.sentence = const Sentence.empty(),
    this.pageStack = const [],
    this.error,
  });

  final Board board;
  final String currentPageId;
  final Sentence sentence;

  /// Pilha de navegação, para o botão "voltar".
  final List<String> pageStack;

  /// Erro a exibir ao cuidador. Falhas de fala não interrompem o uso.
  final AppError? error;

  BoardPage get currentPage => board.page(currentPageId) ?? board.homePage;
  bool get canGoBack => pageStack.isNotEmpty;

  CommunicationState copyWith({
    Board? board,
    String? currentPageId,
    Sentence? sentence,
    List<String>? pageStack,
    AppError? error,
    bool clearError = false,
  }) =>
      CommunicationState(
        board: board ?? this.board,
        currentPageId: currentPageId ?? this.currentPageId,
        sentence: sentence ?? this.sentence,
        pageStack: pageStack ?? this.pageStack,
        error: clearError ? null : (error ?? this.error),
      );
}

class CommunicationController extends Notifier<CommunicationState?> {
  late final BoardRepository _repository;
  late final SpeechProvider _speech;

  @override
  CommunicationState? build() {
    _repository = ref.read(boardRepositoryProvider);
    _speech = ref.read(speechProvider);
    return null; // null = ainda carregando
  }

  Future<void> load() async {
    final result = await _repository.loadActiveBoard();
    switch (result) {
      case Ok(:final value):
        state = CommunicationState(board: value, currentPageId: value.homePageId);
        await _speech.initialize();
      case Err(:final error):
        // Sem board não há app. Este é o único erro verdadeiramente fatal.
        state = null;
        _fatalLoadError = error;
    }
  }

  AppError? _fatalLoadError;
  AppError? get fatalLoadError => _fatalLoadError;

  /// Executa a ação de um botão.
  Future<void> press(AacButton button) async {
    final current = state;
    if (current == null) return;

    switch (button.action) {
      case AddWordAction(:final word, :final spokenText):
        final updated = current.sentence.add(
          SentenceWord(display: word, spoken: spokenText, symbolId: button.symbolId),
        );
        state = current.copyWith(sentence: updated, clearError: true);
        // Ecoa a palavra recém-adicionada: o retorno auditivo imediato é o que
        // confirma à criança que o toque funcionou.
        await _speak(spokenText);

      case SpeakAction(:final text):
        state = current.copyWith(clearError: true);
        await _speak(text);

      case NavigateAction(:final targetPageId):
        if (current.board.page(targetPageId) == null) {
          // A validação na importação deveria impedir isto; se acontecer,
          // ignoramos em silêncio em vez de quebrar no meio de uma frase.
          return;
        }
        state = current.copyWith(
          currentPageId: targetPageId,
          pageStack: [...current.pageStack, current.currentPageId],
          clearError: true,
        );
        // No PODD, navegar é falar. O parceiro de comunicação verbaliza cada
        // passo — "eu gosto", "voltar para a página 1" — e é isso que dá à
        // criança o retorno de que o toque foi registrado e o modelo da língua
        // que ela está construindo. Um botão mudo quebra os dois.
        await _speak(button.label);

      case NavigateBackAction():
        goBack();
        await _speak(button.label);

      case SpeakSentenceAction():
        await speakSentence();

      case ClearSentenceAction():
        clearSentence();

      case BackspaceAction():
        backspace();
    }
  }

  void goBack() {
    final current = state;
    if (current == null || current.pageStack.isEmpty) return;

    final stack = [...current.pageStack];
    final previous = stack.removeLast();
    state = current.copyWith(currentPageId: previous, pageStack: stack);
  }

  void goHome() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      currentPageId: current.board.homePageId,
      pageStack: const [],
    );
  }

  Future<void> speakSentence() async {
    final current = state;
    if (current == null || current.sentence.isEmpty) return;
    await _speak(current.sentence.spokenText);
  }

  void backspace() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(sentence: current.sentence.removeLast());
  }

  void clearSentence() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(sentence: current.sentence.clear());
  }

  /// Atualiza o board em memória e persiste. Usado pelo editor.
  Future<Result<void>> updateBoard(Board board) async {
    final current = state;
    final saved = await _repository.saveBoard(board);

    if (saved.isOk && current != null) {
      // Se a página atual sumiu na edição, volta para a inicial em vez de
      // renderizar uma tela vazia.
      final pageStillExists = board.page(current.currentPageId) != null;
      state = current.copyWith(
        board: board,
        currentPageId: pageStillExists ? current.currentPageId : board.homePageId,
        pageStack: pageStillExists ? current.pageStack : const [],
      );
    }
    return saved;
  }

  Future<void> _speak(String text) async {
    final result = await _speech.speak(text);
    if (result case Err(:final error)) {
      final current = state;
      if (current != null) state = current.copyWith(error: error);
    }
  }

  void dismissError() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(clearError: true);
  }
}

// --- Providers ---------------------------------------------------------------

final boardRepositoryProvider = Provider<BoardRepository>(
  (ref) => throw UnimplementedError(
    'boardRepositoryProvider precisa ser sobrescrito no ProviderScope.',
  ),
);

final speechProvider = Provider<SpeechProvider>(
  (ref) => throw UnimplementedError(
    'speechProvider precisa ser sobrescrito no ProviderScope.',
  ),
);

final communicationControllerProvider =
    NotifierProvider<CommunicationController, CommunicationState?>(
  CommunicationController.new,
);
