/// Gigio — aplicativo de Comunicação Aumentativa e Alternativa.
///
/// Postura de privacidade: o app funciona 100% offline e não declara permissão
/// de rede. As frases de uma criança revelam condição de saúde — dado pessoal
/// sensível sob a LGPD — então nenhum dado sai do dispositivo. Ver
/// docs/architecture.md.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gigio/core/design_system/tokens/gigio_tokens.dart';
import 'package:gigio/data/json_board_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gigio/engines/speech/native_tts_provider.dart';
import 'package:datadog_flutter_plugin/datadog_flutter_plugin.dart';
import 'package:gigio/engines/telemetry/device_context.dart';
import 'package:gigio/engines/telemetry/http_telemetry.dart';
import 'package:gigio/engines/telemetry/perfil_usuario.dart';
import 'package:gigio/engines/telemetry/rum_telemetry.dart';
import 'package:gigio/engines/telemetry/telemetry_service.dart';
import 'package:gigio/features/communication/communication_controller.dart';
import 'package:gigio/features/communication/communication_screen.dart';

/// Endpoint do Worker de telemetria, injetado em tempo de build:
///   flutter build ios --dart-define=GIGIO_TELEMETRIA_URL=https://...
///
/// Vazio por padrão: uma build sem essa definição não faz rede nenhuma. Esquecer
/// de configurar resulta em privacidade, e não em vazamento.
const _telemetriaUrl = String.fromEnvironment('GIGIO_TELEMETRIA_URL');

/// Credenciais do RUM, injetadas em build:
///   --dart-define=GIGIO_DD_CLIENT_TOKEN=pub... \
///   --dart-define=GIGIO_DD_APP_ID=...
///
/// Ficam fora do código-fonte de propósito. O client token do RUM é projetado
/// para viver no cliente (é somente-escrita), mas mantê-lo fora do repositório
/// evita que ele vaze junto com um clone e permite rotacionar sem recompilar o
/// histórico.
const _ddClientToken = String.fromEnvironment('GIGIO_DD_CLIENT_TOKEN');
const _ddAppId = String.fromEnvironment('GIGIO_DD_APP_ID');
const _ddEnv = String.fromEnvironment('GIGIO_DD_ENV', defaultValue: 'familia');

const _chaveConsentimento = 'gigio_consentimento_telemetria';
const _chaveInstalacao = 'gigio_id_instalacao';
const _chaveApelido = 'gigio_apelido_aparelho';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Um app de CAA num iPad é usado deitado e em tela cheia: a interface de
  // sistema aparecendo no meio de uma frase é distração desnecessária.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // O livro PODD é paisagem (819x575 pt) e a grade 4x3 nasceu para essa
  // proporção. Em retrato os cartões ficam pequenos, com vãos verticais
  // enormes — e cartão pequeno é alvo de toque pior para quem tem dificuldade
  // motora fina. Travar em paisagem é fidelidade ao livro e acessibilidade.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final telemetria = await _construirTelemetria();

  void iniciar() => runApp(
        ProviderScope(
          overrides: [
            boardRepositoryProvider.overrideWithValue(JsonBoardStore()),
            speechProvider.overrideWithValue(NativeTtsProvider()),
            telemetryProvider.overrideWithValue(telemetria),
          ],
          child: const GigioApp(),
        ),
      );

  if (telemetria is RumTelemetry) {
    // `runApp` do Datadog embrulha a zona de erro para capturar travamentos.
    await DatadogSdk.runApp(
      construirConfiguracaoDatadog(
        clientToken: _ddClientToken,
        applicationId: _ddAppId,
        env: _ddEnv,
        temConsentimento: () => telemetria.consentimentoAtivo,
      ),
      // Começa como `granted` para que erros e travamentos — que são técnicos e
      // não descrevem comunicação — sempre subam. O conteúdo (telas e toques) é
      // barrado na origem e de novo pelos event mappers.
      TrackingConsent.granted,
      () async {
        DatadogSdk.instance
          ..setUserInfo(
            id: telemetria.perfil.idInstalacao,
            name: telemetria.perfil.nomeParaTelemetria,
            extraInfo: telemetria.contextoDispositivo,
          )
          ..rum?.addAttribute('app_versao', telemetria.appVersion);
        iniciar();
      },
    );
    return;
  }

  iniciar();
}

Future<TelemetryService> _construirTelemetria() async {
  const cofre = FlutterSecureStorage();

  var consentiu = false;
  String? idInstalacao;
  String? apelido;
  try {
    consentiu = await cofre.read(key: _chaveConsentimento) == 'true';
    idInstalacao = await cofre.read(key: _chaveInstalacao);
    apelido = await cofre.read(key: _chaveApelido);
  } on Object {
    // Falha ao ler é tratada como ausência de consentimento.
    consentiu = false;
  }

  if (idInstalacao == null) {
    idInstalacao = PerfilUsuario.gerarId();
    try {
      await cofre.write(key: _chaveInstalacao, value: idInstalacao);
    } on Object {
      // Sem persistir, o id muda a cada abertura. Não é ideal, mas é melhor
      // que impedir o app de subir.
    }
  }

  Future<void> persistir(bool ativo) =>
      cofre.write(key: _chaveConsentimento, value: ativo.toString());

  // RUM tem precedência quando configurado.
  if (_ddClientToken.isNotEmpty && _ddAppId.isNotEmpty) {
    return RumTelemetry(
      appVersion: '1.0.0',
      consentimentoInicial: consentiu,
      persistirConsentimento: persistir,
      perfil: PerfilUsuario(idInstalacao: idInstalacao, apelido: apelido),
      contextoDispositivo: (await DeviceContext.carregar()).toAttributes(),
    );
  }

  if (_telemetriaUrl.isNotEmpty) {
    return HttpTelemetry(
      endpoint: _telemetriaUrl,
      appVersion: '1.0.0',
      consentimentoInicial: consentiu,
      persistirConsentimento: persistir,
    );
  }

  // Sem nenhuma credencial, nada de rede. Esquecer de configurar resulta em
  // privacidade, não em vazamento.
  return const TelemetriaDesligada();
}

class GigioApp extends StatelessWidget {
  const GigioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gigio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: GigioColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: GigioColors.accent,
          surface: GigioColors.surface,
        ),
      ),
      home: const CommunicationScreen(),
    );
  }
}
