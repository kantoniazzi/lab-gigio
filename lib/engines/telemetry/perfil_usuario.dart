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
/// **Com o login do Google ligado**, a origem do id passa a ser a conta, e o
/// e-mail acompanha todos os eventos — inclusive os de tela e toque, que
/// descrevem sobre o que a criança se comunicou. Foi decisão consciente do
/// usuário; ver `docs/telemetria.md`.
library;

import 'dart:math';

class PerfilUsuario {
  const PerfilUsuario({
    required this.idInstalacao,
    this.apelido,
    this.contaId,
    this.email,
    this.nomeConta,
  });

  final String idInstalacao;
  final String? apelido;

  /// Dados da conta Google, quando há sessão. Ver a nota de privacidade no topo
  /// deste arquivo: com login, o e-mail passa a identificar também os eventos
  /// de tela e toque.
  final String? contaId;
  final String? email;
  final String? nomeConta;

  /// Id enviado ao Datadog: a conta quando existe, senão a instalação anônima.
  String get idParaTelemetria => contaId ?? idInstalacao;

  String get nomeParaTelemetria =>
      nomeConta ?? apelido ?? email ?? 'instalação ${idInstalacao.substring(0, 6)}';

  static String gerarId() {
    final rng = Random.secure();
    return List.generate(16, (_) => rng.nextInt(16).toRadixString(16)).join();
  }
}
