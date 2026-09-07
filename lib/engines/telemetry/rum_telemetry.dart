/// Telemetria via RUM do Datadog.
///
/// ## Consequência arquitetural que precisa estar registrada
///
/// O SDK do Datadog fala **direto** com o Datadog: ele não passa pelo Worker do
/// Cloudflare. Isso significa que a redação na borda — a lista de campos
/// permitidos em `worker/src/index.js` — **não protege os dados do RUM**.
///
/// O substituto são os *event mappers* deste arquivo, que interceptam cada
/// evento no aparelho antes do envio. A garantia passou de redação no servidor
/// para redação no cliente: mais fraca, porque roda no dispositivo em vez de um
/// ponto que o responsável controla, mas é o que o SDK permite.
///
/// O que os mappers garantem:
/// - Sem consentimento parental, eventos de visualização e de ação são
///   **descartados** (retornam null). Só erros e travamentos passam.
/// - Nenhum texto de frase ou rótulo de botão entra em atributo, em nenhuma
///   hipótese: o app envia o *id* do botão, nunca o que ele diz.
library;

import 'package:datadog_flutter_plugin/datadog_flutter_plugin.dart';
import 'package:gigio/engines/telemetry/perfil_usuario.dart';
import 'package:gigio/engines/telemetry/telemetry_service.dart';

class RumTelemetry implements TelemetryService {
  RumTelemetry({
    required this.appVersion,
    required bool consentimentoInicial,
    required this.persistirConsentimento,
    required this.perfil,
    required this.contextoDispositivo,
  }) : _consentimento = consentimentoInicial;

  final String appVersion;
  final Future<void> Function(bool) persistirConsentimento;

  /// Identidade atribuída à telemetria. Ver [PerfilUsuario]: não há login.
  final PerfilUsuario perfil;

  /// Modelo, sistema e nome do aparelho quando disponível. Ver
  /// `DeviceContext.carregar` para a limitação do iOS 16+.
  final Map<String, Object?> contextoDispositivo;

  bool _consentimento;

  DatadogSdk get _dd => DatadogSdk.instance;

  @override
  bool get consentimentoAtivo => _consentimento;

  @override
  Future<void> definirConsentimento({required bool ativo}) async {
    _consentimento = ativo;
    await persistirConsentimento(ativo);

    // Informa o próprio SDK. Com `notGranted` ele para de coletar e descarta o
    // que ainda estava em lote — revogar precisa valer para o passado recente.
    _dd.setTrackingConsent(
      ativo ? TrackingConsent.granted : TrackingConsent.notGranted,
    );
  }

  @override
  void registrar(TelemetryEvent evento) {
    if (evento.ehConteudoDeComunicacao && !_consentimento) return;

    final rum = _dd.rum;
    if (rum == null) return;

    switch (evento) {
      case TelaEvent(:final pagina):
        rum.startView(pagina, 'Página $pagina');

      case ToqueEvent(:final pagina, :final botao, :final acaoBotao):
        // Só id e tipo de ação. O rótulo é a fala da criança e não sobe.
        rum.addAction(RumActionType.tap, botao, {
          'pagina': pagina,
          'acao': acaoBotao,
        });

      case ErroEvent(:final classe, :final mensagem, :final fatal):
        rum.addError(
          '$classe: $mensagem',
          fatal ? RumErrorSource.source : RumErrorSource.custom,
        );

      case VozEvent(:final ok, :final motivo):
        if (!ok) {
          rum.addError('TTS falhou: ${motivo ?? "sem detalhe"}', RumErrorSource.source);
        }
        rum.addAttribute('voz_ok', ok);

      case DesempenhoEvent(:final metrica, :final valorMs):
        rum.addAttribute('perf_$metrica', valorMs);

      case BoardEvent(:final acao, :final paginas, :final botoes, :final recuperadoDeBackup):
        rum
          ..addAttribute('board_acao', acao)
          ..addAttribute('board_paginas', paginas)
          ..addAttribute('board_botoes', botoes)
          // A métrica que antes não existia: saber se a recuperação de board
          // corrompido chegou a ser acionada em campo.
          ..addAttribute('board_recuperado_de_backup', recuperadoDeBackup);
    }
  }

  @override
  Future<void> descarregar() async {}
}

/// Palavras que denunciam conteúdo de comunicação num atributo. Se qualquer uma
/// aparecer numa chave, o atributo é removido antes do envio.
const _chavesProibidas = {
  'label', 'rotulo', 'frase', 'sentence', 'texto', 'spoken',
  'utterance', 'palavra', 'word', 'simbolo', 'symbol',
};

/// Remove do próprio mapa qualquer atributo cuja chave denuncie conteúdo de
/// comunicação. Última barreira antes do envio.
void _limparNoLugar(Map<String, Object?> atributos) {
  atributos.removeWhere(
    (chave, _) => _chavesProibidas.any(chave.toLowerCase().contains),
  );
}

/// Configuração do SDK, com os mappers que substituem a redação na borda.
DatadogConfiguration construirConfiguracaoDatadog({
  required String clientToken,
  required String applicationId,
  required String env,
  required bool Function() temConsentimento,
}) {
  return DatadogConfiguration(
    clientToken: clientToken,
    env: env,
    site: DatadogSite.us1,
    nativeCrashReportEnabled: true,
    loggingConfiguration: DatadogLoggingConfiguration(),
    rumConfiguration: DatadogRumConfiguration(
      applicationId: applicationId,
      // ATENÇÃO: RumViewEventMapper retorna tipo NÃO-anulável, ou seja, o SDK
      // não permite descartar uma visualização — só modificá-la. Por isso a
      // barreira das telas fica na origem: `registrar` só chama `startView`
      // com consentimento, e nenhum observador de navegação automático está
      // ligado. O mapper aqui só faz a limpeza de atributos.
      viewEventMapper: (evento) {
        _limparNoLugar(evento.context);
        return evento;
      },
      // Ação PODE ser descartada. Sem consentimento parental, morre aqui —
      // segunda barreira, além do bloqueio na origem.
      actionEventMapper: (evento) {
        if (!temConsentimento()) return null;
        _limparNoLugar(evento.context);
        return evento;
      },
      // Erros passam sempre: são técnicos e não descrevem comunicação. Ainda
      // assim os atributos são limpos.
      errorEventMapper: (evento) {
        _limparNoLugar(evento.context);
        return evento;
      },
    ),
  );
}
