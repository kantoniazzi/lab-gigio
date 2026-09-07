/// Testes que protegem a postura de privacidade do app.
///
/// Estas garantias são fáceis de perder por acidente — basta alguém adicionar
/// uma dependência que faça rede, ou colar uma permissão num manifesto. Aqui
/// elas viram falha de build.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('privacidade', () {
    test('só o módulo de telemetria faz rede', () {
      // A permissão INTERNET existe desde a telemetria, então a garantia
      // deixou de ser estrutural. Este teste é o que a substitui: nenhuma
      // outra camada pode abrir conexão. Se o núcleo de comunicação ganhar
      // acesso à rede, as frases da criança passam a poder vazar.
      final infratores = <String>[];
      const permitido = 'lib/engines/telemetry';

      for (final file in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        if (file.path.contains(permitido)) continue;
        final fonte = file.readAsStringSync();
        for (final proibido in const [
          "import 'dart:io'",
          "package:http/",
          'HttpClient(',
          'WebSocket',
        ]) {
          // dart:io também serve para arquivo; só acusamos o uso de rede.
          if (proibido == "import 'dart:io'" && !fonte.contains('HttpClient')) {
            continue;
          }
          if (fonte.contains(proibido)) infratores.add('${file.path} -> $proibido');
        }
      }

      expect(infratores, isEmpty,
          reason: 'Rede fora de $permitido:\n  ${infratores.join('\n  ')}');
    });

    test('conteúdo de comunicação exige consentimento no modelo', () {
      final fonte =
          File('lib/engines/telemetry/telemetry_service.dart').readAsStringSync();

      // Tela e toque revelam sobre o que a criança se comunicou; precisam estar
      // marcados como conteúdo para o serviço poder barrá-los sem consentimento.
      expect(fonte, contains('ehConteudoDeComunicacao'));
      for (final classe in const ['TelaEvent', 'ToqueEvent']) {
        final trecho = fonte.substring(fonte.indexOf('class $classe'));
        expect(trecho.contains('ehConteudoDeComunicacao => true'), isTrue,
            reason: '$classe precisa ser marcado como conteúdo de comunicação');
      }
    });

    test('a telemetria nunca envia rótulo nem texto falado', () {
      final fonte =
          File('lib/engines/telemetry/telemetry_service.dart').readAsStringSync();
      for (final proibido in const ['label', 'spokenText', 'displayText', 'rotulo']) {
        expect(fonte.contains("'$proibido'"), isFalse,
            reason: 'O campo $proibido é a fala da criança e não pode subir.');
      }
    });

    test('nenhum SDK de telemetria ou analytics entrou no pubspec', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();

      const proibidos = [
        'firebase_analytics',
        'firebase_crashlytics',
        'sentry_flutter',
        'amplitude_flutter',
        'mixpanel_flutter',
        'posthog_flutter',
        'appsflyer',
        'facebook_app_events',
      ];

      final encontrados =
          proibidos.where((p) => pubspec.contains(p)).toList();

      expect(
        encontrados,
        isEmpty,
        reason: 'O Gigio não coleta telemetria. Pacotes encontrados: $encontrados',
      );
    });

    test('o PIN do cuidador nunca é comparado em texto claro', () {
      final source =
          File('lib/features/editor/caregiver_pin_service.dart').readAsStringSync();

      expect(source, contains('Hmac'),
          reason: 'O PIN precisa ser derivado com PBKDF2-HMAC.');
      expect(source, contains('_constantTimeEquals'),
          reason: 'A verificação do PIN precisa ser em tempo constante.');
      expect(source, contains('Random.secure'),
          reason: 'O salt precisa vir de um gerador criptograficamente seguro.');
    });
  });
}
