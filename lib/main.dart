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
import 'package:gigio/engines/auth/auth_service.dart';
import 'package:gigio/engines/auth/google_auth_service.dart';
import 'package:gigio/engines/speech/native_tts_provider.dart';
import 'package:datadog_flutter_plugin/datadog_flutter_plugin.dart';
import 'package:datadog_session_replay/datadog_session_replay.dart';
import 'package:gigio/engines/telemetry/device_context.dart';
import 'package:gigio/engines/telemetry/http_telemetry.dart';
import 'package:gigio/engines/telemetry/perfil_usuario.dart';
import 'package:gigio/engines/telemetry/rum_telemetry.dart';
import 'package:gigio/engines/telemetry/telemetry_service.dart';
import 'package:gigio/features/communication/communication_controller.dart';
import 'package:gigio/features/auth/auth_gate.dart';

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
const _ddEnv = String.fromEnvironment('GIGIO_DD_ENV', defaultValue: 'prod');

/// Client ID do OAuth do Google para iOS, injetado em build:
///   --dart-define=GIGIO_GOOGLE_CLIENT_ID=...apps.googleusercontent.com
///
/// Sem ele o app **pula o login** e abre direto no board: uma build mal
/// configurada não pode prender a criança numa tela da qual ela não sai.
const _googleClientId = String.fromEnvironment('GIGIO_GOOGLE_CLIENT_ID');

/// Client ID do tipo **Web application**, exigido no Android:
///   --dart-define=GIGIO_GOOGLE_SERVER_CLIENT_ID=...apps.googleusercontent.com
///
/// O client ID de Android não entra aqui — o Google o reconhece pela combinação
/// de pacote + SHA-1.
const _googleServerClientId =
    String.fromEnvironment('GIGIO_GOOGLE_SERVER_CLIENT_ID');

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

  final AuthService auth =
      _googleClientId.isEmpty && _googleServerClientId.isEmpty
          ? const AuthDesativado()
          : GoogleAuthService(
              clientId: _googleClientId,
              serverClientId: _googleServerClientId,
            );

  // Lido do cofre local, sem rede: a sessão salva é a fonte de verdade.
  final perfilInicial = await auth.perfilSalvo();

  final telemetria = await _construirTelemetria(perfilInicial);

  void iniciar() => runApp(
        ProviderScope(
          overrides: [
            boardRepositoryProvider.overrideWithValue(JsonBoardStore()),
            speechProvider.overrideWithValue(NativeTtsProvider()),
            telemetryProvider.overrideWithValue(telemetria),
            authServiceProvider.overrideWithValue(auth),
          ],
          child: const GigioApp(),
        ),
      );

  if (telemetria is RumTelemetry) {
    final configuracao = construirConfiguracaoDatadog(
      clientToken: _ddClientToken,
      applicationId: _ddAppId,
      env: _ddEnv,
      temConsentimento: () => telemetria.consentimentoAtivo,
    )..enableSessionReplay(
        DatadogSessionReplayConfiguration(
          // 100% das sessões amostradas pelo RUM terão gravação.
          replaySampleRate: 100,

          // Mostra o texto, mas mantém mascarado tudo que for campo protegido —
          // o PIN do cuidador usa `obscureText` e continua invisível.
          textAndInputPrivacyLevel: TextAndInputPrivacyLevel.maskSensitiveInputs,

          // Grava apenas imagens embarcadas no app. Com `maskAll` (o padrão) o
          // board apareceria em branco e a gravação seria inútil; com
          // `maskNone` entrariam também imagens vindas da rede.
          //
          // ATENÇÃO: os pictogramas PODD e as FOTOS DA FAMÍLIA E DAS
          // TERAPEUTAS são assets embarcados, então aparecem na gravação.
          // Ver docs/telemetria.md.
          imagePrivacyLevel: ImagePrivacyLevel.maskNonAssetsOnly,

          // Mostra onde a criança tocou — é o ponto da gravação.
          touchPrivacyLevel: TouchPrivacyLevel.show,
        ),
      );

    // `runApp` do Datadog embrulha a zona de erro para capturar travamentos.
    await DatadogSdk.runApp(
      configuracao,
      // Começa como `granted` para que erros e travamentos — que são técnicos e
      // não descrevem comunicação — sempre subam. O conteúdo (telas e toques) é
      // barrado na origem e de novo pelos event mappers.
      TrackingConsent.granted,
      () async {
        // Identidade da conta Google em todos os eventos, incluindo os de tela
        // e toque. Decisão consciente do usuário, registrada em
        // docs/telemetria.md: isso liga um e-mail real ao que a criança
        // comunicou. Sem login, cai para o id de instalação anônimo.
        DatadogSdk.instance
          ..setUserInfo(
            id: telemetria.perfil.idParaTelemetria,
            name: telemetria.perfil.nomeParaTelemetria,
            email: telemetria.perfil.email,
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

Future<TelemetryService> _construirTelemetria(PerfilAutenticado? autenticado) async {
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
      perfil: PerfilUsuario(
        idInstalacao: idInstalacao,
        apelido: apelido,
        contaId: autenticado?.id,
        email: autenticado?.email,
        nomeConta: autenticado?.nome,
      ),
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

  static final _chaveCaptura = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final app = _construirApp();

    // A gravação só envolve a árvore quando o SDK e o Session Replay estão de
    // pé. Sem isso, o app roda igual — telemetria jamais pode ser pré-requisito
    // para a criança falar.
    final rum = DatadogSdk.instance.rum;
    final replay = DatadogSessionReplay.instance;
    if (rum == null || replay == null) return app;

    return SessionReplayCapture(
      key: _chaveCaptura,
      rum: rum,
      sessionReplay: replay,
      child: app,
    );
  }

  Widget _construirApp() {
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
      home: const AuthGate(),
    );
  }
}
