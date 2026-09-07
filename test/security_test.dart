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
    test('o manifesto de release não concede acesso à internet', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

      final concedeInternet = RegExp(
        r'<uses-permission[^>]*android\.permission\.INTERNET(?![^>]*tools:node\s*=\s*"remove")',
      ).hasMatch(manifest);

      expect(
        concedeInternet,
        isFalse,
        reason: 'O Gigio é offline por decisão de privacidade: as frases de uma '
            'criança são dado pessoal sensível (LGPD art. 11, art. 14). '
            'Conceder INTERNET remove a garantia estrutural de que nada sai do '
            'dispositivo. Se a sincronização em nuvem for mesmo desejada, esta '
            'mudança precisa vir acompanhada de consentimento explícito do '
            'responsável — e este teste deve ser reescrito conscientemente.',
      );
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
