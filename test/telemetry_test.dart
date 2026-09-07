/// O consentimento parental precisa barrar de verdade, e não só na interface.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gigio/engines/telemetry/http_telemetry.dart';
import 'package:gigio/engines/telemetry/telemetry_service.dart';
import 'package:http/http.dart' as http;

class ClienteFalso extends http.BaseClient {
  final List<List<Map<String, Object?>>> lotes = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final corpo = await (request as http.Request).finalize().bytesToString();
    lotes.add((jsonDecode(corpo) as List).cast<Map<String, Object?>>());
    return http.StreamedResponse(const Stream.empty(), 202);
  }

  List<Map<String, Object?>> get eventos => lotes.expand((l) => l).toList();
}

void main() {
  late ClienteFalso cliente;
  var consentimentoSalvo = false;

  HttpTelemetry criar({required bool consentido}) {
    cliente = ClienteFalso();
    return HttpTelemetry(
      endpoint: 'https://exemplo.invalido/eventos',
      appVersion: '1.0.0',
      consentimentoInicial: consentido,
      persistirConsentimento: (v) async => consentimentoSalvo = v,
      cliente: cliente,
    );
  }

  test('sem consentimento, tela e toque nem entram na fila', () async {
    final t = criar(consentido: false);
    t.registrar(const TelaEvent('5'));
    t.registrar(const ToqueEvent(pagina: '5', botao: '5-r0c0', acaoBotao: 'addWord'));
    await t.descarregar();

    expect(cliente.eventos, isEmpty,
        reason: 'Página e botão revelam sobre o que a criança se comunicou.');
  });

  test('sem consentimento, eventos técnicos continuam subindo', () async {
    final t = criar(consentido: false);
    t.registrar(const ErroEvent(classe: 'SpeechError', mensagem: 'falhou'));
    t.registrar(const VozEvent(ok: false, motivo: 'engine indisponível'));
    await t.descarregar();

    expect(cliente.eventos.length, 2);
    expect(cliente.eventos.map((e) => e['tipo']), containsAll(['erro', 'voz']));
  });

  test('com consentimento, tela e toque sobem marcados', () async {
    final t = criar(consentido: true);
    t.registrar(const ToqueEvent(pagina: '5', botao: '5-r0c0', acaoBotao: 'addWord'));
    await t.descarregar();

    final evento = cliente.eventos.single;
    expect(evento['tipo'], 'toque');
    expect(evento['consentido'], isTrue);
    expect(evento['botao'], '5-r0c0');
  });

  test('nenhum evento carrega rótulo ou texto falado', () async {
    final t = criar(consentido: true);
    t.registrar(const ToqueEvent(pagina: '5', botao: '5-r0c0', acaoBotao: 'addWord'));
    t.registrar(const TelaEvent('banheiro'));
    await t.descarregar();

    final serializado = jsonEncode(cliente.eventos);
    for (final proibido in const ['label', 'rotulo', 'frase', 'texto', 'dói']) {
      expect(serializado.contains(proibido), isFalse, reason: 'vazou "$proibido"');
    }
  });

  test('revogar descarta o que ainda não subiu', () async {
    final t = criar(consentido: true);
    t.registrar(const TelaEvent('5'));
    t.registrar(const ErroEvent(classe: 'X', mensagem: 'y'));

    await t.definirConsentimento(ativo: false);
    await t.descarregar();

    expect(consentimentoSalvo, isFalse);
    expect(cliente.eventos.map((e) => e['tipo']), ['erro'],
        reason: 'Revogar precisa valer para o passado recente, não só para o futuro.');
  });

  test('sem endpoint configurado, nada é enviado', () async {
    final t = HttpTelemetry(
      endpoint: '',
      appVersion: '1.0.0',
      consentimentoInicial: true,
      persistirConsentimento: (_) async {},
      cliente: cliente = ClienteFalso(),
    );
    t.registrar(const ErroEvent(classe: 'X', mensagem: 'y'));
    await t.descarregar();

    expect(cliente.eventos, isEmpty,
        reason: 'Build sem --dart-define não pode fazer rede alguma.');
  });

  test('falha de rede não propaga', () async {
    final t = HttpTelemetry(
      endpoint: 'https://exemplo.invalido/eventos',
      appVersion: '1.0.0',
      consentimentoInicial: false,
      persistirConsentimento: (_) async {},
    );
    t.registrar(const ErroEvent(classe: 'X', mensagem: 'y'));

    // Telemetria jamais pode alterar o comportamento do app.
    await expectLater(t.descarregar(), completes);
  });
}
