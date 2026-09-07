/// Contexto do aparelho, anexado a todo evento de telemetria.
library;

import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceContext {
  const DeviceContext({
    required this.nome,
    required this.modelo,
    required this.sistema,
    required this.versaoSistema,
  });

  /// Nome atribuído pelo dono do aparelho, quando disponível.
  ///
  /// **Limitação do iOS:** desde o iOS 16 a Apple não devolve mais o nome
  /// escolhido pelo usuário ("iPad da Gigi") sem um *entitlement* especial —
  /// retorna o modelo. No Android o nome real costuma vir.
  final String nome;
  final String modelo;
  final String sistema;
  final String versaoSistema;

  Map<String, Object?> toAttributes() => {
        'dispositivo_nome': nome,
        'dispositivo_modelo': modelo,
        'dispositivo_so': sistema,
        'dispositivo_so_versao': versaoSistema,
      };

  static Future<DeviceContext> carregar() async {
    final plugin = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        final web = await plugin.webBrowserInfo;
        return DeviceContext(
          nome: web.browserName.name,
          modelo: web.browserName.name,
          sistema: 'web',
          versaoSistema: web.appVersion ?? 'desconhecida',
        );
      }
      if (Platform.isIOS) {
        final ios = await plugin.iosInfo;
        return DeviceContext(
          nome: ios.name,
          modelo: ios.utsname.machine,
          sistema: 'iOS',
          versaoSistema: ios.systemVersion,
        );
      }
      if (Platform.isAndroid) {
        final android = await plugin.androidInfo;
        return DeviceContext(
          nome: android.device,
          modelo: '${android.manufacturer} ${android.model}',
          sistema: 'Android',
          versaoSistema: android.version.release,
        );
      }
    } on Object {
      // Contexto de aparelho é enfeite: nunca pode impedir o app de abrir.
    }
    return const DeviceContext(
      nome: 'desconhecido',
      modelo: 'desconhecido',
      sistema: 'desconhecido',
      versaoSistema: 'desconhecida',
    );
  }
}
