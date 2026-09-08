/// Autenticação do usuário.
///
/// ## Regra central deste módulo
///
/// O Gigio é um app de comunicação. Se a Gigi abrir e encontrar uma parede de
/// login, ela fica sem voz até um adulto aparecer. Por isso:
///
/// **O perfil salvo localmente é a fonte de verdade, e nunca é revalidado com o
/// Google na abertura.** O login acontece uma vez; a partir daí o app abre
/// direto no board, com ou sem internet. Renovação de token, quando houver,
/// roda em segundo plano e falhar nela jamais desloga.
library;

import 'package:gigio/core/errors/app_error.dart';
import 'package:gigio/core/result/result.dart';

class PerfilAutenticado {
  const PerfilAutenticado({
    required this.id,
    required this.email,
    this.nome,
    this.fotoUrl,
  });

  final String id;
  final String email;
  final String? nome;
  final String? fotoUrl;

  String get nomeExibido => nome?.trim().isNotEmpty ?? false ? nome! : email;

  Map<String, Object?> toJson() =>
      {'id': id, 'email': email, 'nome': nome, 'fotoUrl': fotoUrl};

  static PerfilAutenticado? fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final email = json['email'];
    if (id is! String || email is! String) return null;
    return PerfilAutenticado(
      id: id,
      email: email,
      nome: json['nome'] as String?,
      fotoUrl: json['fotoUrl'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PerfilAutenticado && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);
}

abstract interface class AuthService {
  /// Perfil salvo, lido do armazenamento local **sem tocar na rede**.
  Future<PerfilAutenticado?> perfilSalvo();

  /// Abre o fluxo de login do provedor. Só é chamado por ação explícita.
  Future<Result<PerfilAutenticado>> entrar();

  Future<void> sair();

  /// Se o login está configurado nesta build. Quando falso, o app pula a tela
  /// de login — uma build mal configurada não pode prender a criança numa tela
  /// de erro.
  bool get disponivel;
}

/// Usada quando não há client ID configurado: o app abre direto no board.
class AuthDesativado implements AuthService {
  const AuthDesativado();

  @override
  bool get disponivel => false;

  @override
  Future<PerfilAutenticado?> perfilSalvo() async => null;

  @override
  Future<Result<PerfilAutenticado>> entrar() async =>
      const Err(AuthError('Login não está configurado nesta versão.'));

  @override
  Future<void> sair() async {}
}
