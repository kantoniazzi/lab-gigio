/// Identidade atribuída à telemetria.
///
/// **Não há login no Gigio.** A distribuição é por TestFlight e teste fechado
/// da Play, sem contas. Então "usuário logado" não existe, e inventar um seria
/// pior: associar a comunicação de uma criança a uma identidade estável é o
/// desenho mais sensível possível.
///
/// O que existe:
/// - um **id de instalação** aleatório, gerado no aparelho e sem relação com
///   pessoa alguma;
/// - um **apelido opcional** que o cuidador digita nas configurações, para
///   distinguir aparelhos ("iPad da escola", "iPad de casa").
///
/// Quando houver login de verdade, troca-se a origem do id sem mexer no resto.
library;

import 'dart:math';

class PerfilUsuario {
  const PerfilUsuario({required this.idInstalacao, this.apelido});

  final String idInstalacao;
  final String? apelido;

  /// Nome exibido no Datadog. Sem apelido, mostra a instalação abreviada — o
  /// suficiente para distinguir aparelhos sem identificar ninguém.
  String get nomeParaTelemetria =>
      apelido ?? 'instalação ${idInstalacao.substring(0, 6)}';

  static String gerarId() {
    final rng = Random.secure();
    return List.generate(16, (_) => rng.nextInt(16).toRadixString(16)).join();
  }
}
