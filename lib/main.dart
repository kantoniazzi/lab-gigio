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
import 'package:gigio/engines/speech/native_tts_provider.dart';
import 'package:gigio/features/communication/communication_controller.dart';
import 'package:gigio/features/communication/communication_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Um app de CAA num iPad é usado deitado e em tela cheia: a interface de
  // sistema aparecendo no meio de uma frase é distração desnecessária.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    ProviderScope(
      overrides: [
        boardRepositoryProvider.overrideWithValue(JsonBoardStore()),
        speechProvider.overrideWithValue(NativeTtsProvider()),
      ],
      child: const GigioApp(),
    ),
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
