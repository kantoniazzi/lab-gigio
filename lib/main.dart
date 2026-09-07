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
import 'package:gigio/engines/telemetry/http_telemetry.dart';
import 'package:gigio/engines/telemetry/telemetry_service.dart';
import 'package:gigio/features/communication/communication_controller.dart';
import 'package:gigio/features/communication/communication_screen.dart';

/// Endpoint do Worker de telemetria, injetado em tempo de build:
///   flutter build ios --dart-define=GIGIO_TELEMETRIA_URL=https://...
///
/// Vazio por padrão: uma build sem essa definição não faz rede nenhuma. Esquecer
/// de configurar resulta em privacidade, e não em vazamento.
const _telemetriaUrl = String.fromEnvironment('GIGIO_TELEMETRIA_URL');

const _chaveConsentimento = 'gigio_consentimento_telemetria';

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

  runApp(
    ProviderScope(
      overrides: [
        boardRepositoryProvider.overrideWithValue(JsonBoardStore()),
        speechProvider.overrideWithValue(NativeTtsProvider()),
        telemetryProvider.overrideWithValue(telemetria),
      ],
      child: const GigioApp(),
    ),
  );
}

Future<TelemetryService> _construirTelemetria() async {
  if (_telemetriaUrl.isEmpty) return const TelemetriaDesligada();

  const cofre = FlutterSecureStorage();
  var consentiu = false;
  try {
    consentiu = await cofre.read(key: _chaveConsentimento) == 'true';
  } on Object {
    // Falha ao ler o consentimento é tratada como ausência de consentimento.
    consentiu = false;
  }

  return HttpTelemetry(
    endpoint: _telemetriaUrl,
    appVersion: '1.0.0',
    consentimentoInicial: consentiu,
    persistirConsentimento: (ativo) =>
        cofre.write(key: _chaveConsentimento, value: ativo.toString()),
  );
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
