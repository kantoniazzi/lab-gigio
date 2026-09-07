/// Testes que protegem decisões arquiteturais.
///
/// A regra "domínio não importa Flutter" não é expressável em
/// `analysis_options.yaml`, então é garantida aqui: se alguém importar Flutter
/// dentro de `lib/domain/`, o build quebra com uma mensagem que explica o
/// porquê.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fronteiras de camada', () {
    test('lib/domain/ não depende de Flutter', () {
      final domainDir = Directory('lib/domain');
      expect(domainDir.existsSync(), isTrue,
          reason: 'A camada de domínio deveria existir em lib/domain/.');

      final offenders = <String>[];
      final dartFiles = domainDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final source = file.readAsStringSync();
        final imports = RegExp(
          r'''^\s*import\s+['"]([^'"]+)['"]''',
          multiLine: true,
        ).allMatches(source).map((m) => m.group(1)!);

        for (final import in imports) {
          if (import.startsWith('package:flutter/') ||
              import.startsWith('package:flutter_')) {
            offenders.add('${file.path} → $import');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'A camada de domínio é Dart puro e precisa continuar assim, '
            'para que o núcleo de comunicação possa ser testado, reusado e '
            'portado sem arrastar a UI junto. Ver docs/architecture.md.\n'
            'Violações encontradas:\n  ${offenders.join('\n  ')}',
      );
    });
  });
}
