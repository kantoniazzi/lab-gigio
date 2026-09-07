/// Contrato de telemetria.
///
/// Duas regras que valem para qualquer implementação:
///
/// 1. **Telemetria nunca altera o comportamento do app.** Toda falha é
///    engolida. Um app de CAA não pode deixar de falar porque um evento não
///    subiu.
/// 2. **Navegação e toque exigem consentimento parental explícito**, desligado
///    por padrão. As páginas do livro da Gigi têm nomes como "algo está
///    errado", "partes do corpo" e "banheiro" — a sequência de telas revela
///    condição de saúde. Sem consentimento, só sobem eventos técnicos.
library;

sealed class TelemetryEvent {
  const TelemetryEvent();
  Map<String, Object?> toJson();

  /// Se o evento descreve o que a criança comunicou. Estes só são enviados com
  /// consentimento parental ativo.
  bool get ehConteudoDeComunicacao => false;
}

final class ErroEvent extends TelemetryEvent {
  const ErroEvent({required this.classe, required this.mensagem, this.fatal = false});
  final String classe;
  final String mensagem;
  final bool fatal;

  @override
  Map<String, Object?> toJson() =>
      {'tipo': 'erro', 'classe': classe, 'mensagem': mensagem, 'fatal': fatal};
}

final class DesempenhoEvent extends TelemetryEvent {
  const DesempenhoEvent(this.metrica, this.valorMs);
  final String metrica;
  final int valorMs;

  @override
  Map<String, Object?> toJson() =>
      {'tipo': 'desempenho', 'metrica': metrica, 'valorMs': valorMs};
}

final class VozEvent extends TelemetryEvent {
  const VozEvent({required this.ok, this.motivo});
  final bool ok;
  final String? motivo;

  @override
  Map<String, Object?> toJson() => {'tipo': 'voz', 'ok': ok, 'motivo': motivo};
}

/// Saúde do board. `recuperadoDeBackup` é a métrica que hoje não temos: o
/// caminho de recuperação está implementado e testado, mas não sabemos se já
/// salvou alguém em campo.
final class BoardEvent extends TelemetryEvent {
  const BoardEvent({
    required this.acao,
    this.paginas,
    this.botoes,
    this.recuperadoDeBackup = false,
  });
  final String acao;
  final int? paginas;
  final int? botoes;
  final bool recuperadoDeBackup;

  @override
  Map<String, Object?> toJson() => {
        'tipo': 'board',
        'acao': acao,
        if (paginas != null) 'paginas': paginas,
        if (botoes != null) 'botoes': botoes,
        'recuperadoDeBackup': recuperadoDeBackup,
      };
}

/// Página visitada. **Conteúdo de comunicação.**
final class TelaEvent extends TelemetryEvent {
  const TelaEvent(this.pagina);
  final String pagina;

  @override
  bool get ehConteudoDeComunicacao => true;

  @override
  Map<String, Object?> toJson() => {'tipo': 'tela', 'pagina': pagina};
}

/// Botão tocado. **Conteúdo de comunicação.**
///
/// Envia o *id* do botão e o tipo da ação — nunca o rótulo, nunca o texto
/// falado. O id já é reveladoro suficiente; o rótulo seria a fala literal.
final class ToqueEvent extends TelemetryEvent {
  const ToqueEvent({required this.pagina, required this.botao, required this.acaoBotao});
  final String pagina;
  final String botao;
  final String acaoBotao;

  @override
  bool get ehConteudoDeComunicacao => true;

  @override
  Map<String, Object?> toJson() =>
      {'tipo': 'toque', 'pagina': pagina, 'botao': botao, 'acaoBotao': acaoBotao};
}

abstract interface class TelemetryService {
  /// Registra um evento. Nunca lança, nunca bloqueia.
  void registrar(TelemetryEvent evento);

  /// Consentimento parental para eventos de conteúdo. Desligado por padrão.
  bool get consentimentoAtivo;
  Future<void> definirConsentimento({required bool ativo});

  Future<void> descarregar();
}

/// Implementação padrão: não faz nada.
///
/// É esta que roda quando não há endpoint configurado. Fazer o "nada" ser o
/// padrão significa que esquecer de configurar resulta em privacidade, e não
/// em vazamento.
class TelemetriaDesligada implements TelemetryService {
  const TelemetriaDesligada();

  @override
  void registrar(TelemetryEvent evento) {}

  @override
  bool get consentimentoAtivo => false;

  @override
  Future<void> definirConsentimento({required bool ativo}) async {}

  @override
  Future<void> descarregar() async {}
}
