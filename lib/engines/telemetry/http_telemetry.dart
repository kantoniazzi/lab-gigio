/// Telemetria que envia para o Worker do Cloudflare, que por sua vez repassa
/// ao Datadog depois de passar os eventos por uma lista de campos permitidos.
///
/// O app nunca fala com o Datadog diretamente: as credenciais ficam no Worker,
/// e a redação na borda é a última barreira antes de o dado sair do controle
/// da família.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:gigio/engines/telemetry/telemetry_service.dart';
import 'package:http/http.dart' as http;

class HttpTelemetry implements TelemetryService {
  HttpTelemetry({
    required this.endpoint,
    required this.appVersion,
    required bool consentimentoInicial,
    required this.persistirConsentimento,
    http.Client? cliente,
  })  : _consentimento = consentimentoInicial,
        _cliente = cliente ?? http.Client();

  /// URL do Worker. Sem ela, nada é enviado.
  final String endpoint;
  final String appVersion;

  /// Grava o consentimento; injetado para não acoplar a telemetria ao
  /// armazenamento.
  final Future<void> Function(bool) persistirConsentimento;

  final http.Client _cliente;
  final List<Map<String, Object?>> _fila = [];
  Timer? _timer;
  bool _consentimento;

  /// Identificadores de sessão e instalação, aleatórios e locais. Não há login
  /// no app, então não existe "usuário logado" para identificar — e associar a
  /// comunicação de uma criança a uma identidade estável seria o pior dos
  /// mundos. A instalação é o grão mais fino que faz sentido.
  final String _sessao = _aleatorio();
  static String? _instalacao;

  static String _aleatorio() {
    final rng = Random.secure();
    return List.generate(16, (_) => rng.nextInt(16).toRadixString(16)).join();
  }

  @override
  bool get consentimentoAtivo => _consentimento;

  @override
  Future<void> definirConsentimento({required bool ativo}) async {
    _consentimento = ativo;
    await persistirConsentimento(ativo);
    if (!ativo) {
      // Ao revogar, o que ainda não subiu é descartado. Revogar precisa valer
      // para o passado recente também, não só para o futuro.
      _fila.removeWhere((e) => e['tipo'] == 'tela' || e['tipo'] == 'toque');
    }
  }

  @override
  void registrar(TelemetryEvent evento) {
    // A porta principal: sem consentimento, conteúdo de comunicação nem entra
    // na fila. O Worker reconfere, mas a decisão certa é não coletar.
    if (evento.ehConteudoDeComunicacao && !_consentimento) return;
    if (endpoint.isEmpty) return;

    _instalacao ??= _aleatorio();

    _fila.add({
      ...evento.toJson(),
      'sessao': _sessao,
      'instalacao': _instalacao,
      'appVersion': appVersion,
      'plataforma': _plataforma,
      if (evento.ehConteudoDeComunicacao) 'consentido': true,
    });

    if (_fila.length >= 50) {
      unawaited(descarregar());
    } else {
      _timer ??= Timer(const Duration(seconds: 30), () => unawaited(descarregar()));
    }
  }

  String get _plataforma {
    if (kIsWeb) return 'web';
    try {
      return Platform.operatingSystem;
    } on Object {
      return 'desconhecida';
    }
  }

  @override
  Future<void> descarregar() async {
    _timer?.cancel();
    _timer = null;
    if (_fila.isEmpty) return;

    final lote = List<Map<String, Object?>>.from(_fila);
    _fila.clear();

    try {
      await _cliente
          .post(
            Uri.parse(endpoint),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(lote),
          )
          .timeout(const Duration(seconds: 10));
    } on Object {
      // Silêncio deliberado. Telemetria jamais pode alterar o comportamento do
      // app, e um evento perdido não é problema — perder a voz seria.
    }
  }
}
