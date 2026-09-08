/// Login com conta Google.
///
/// Usa a API v7 do `google_sign_in`, que trocou o antigo `signIn()` por
/// `initialize()` seguido de `authenticate()`.
///
/// **A regra que mais importa aqui** está em [perfilSalvo]: ele lê do cofre
/// local e **não toca na rede**. Num app de CAA, revalidar a sessão a cada
/// abertura significaria que ficar sem internet deixa a criança sem voz.
library;

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gigio/core/errors/app_error.dart';
import 'package:gigio/core/result/result.dart';
import 'package:gigio/engines/auth/auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService implements AuthService {
  GoogleAuthService({
    required this.clientId,
    FlutterSecureStorage? cofre,
  }) : _cofre = cofre ?? const FlutterSecureStorage();

  static const _chavePerfil = 'gigio_perfil_autenticado';

  final String clientId;
  final FlutterSecureStorage _cofre;

  bool _iniciado = false;

  @override
  bool get disponivel => clientId.isNotEmpty;

  Future<void> _garantirInicializado() async {
    if (_iniciado) return;
    await GoogleSignIn.instance.initialize(clientId: clientId);
    _iniciado = true;
  }

  @override
  Future<PerfilAutenticado?> perfilSalvo() async {
    try {
      final bruto = await _cofre.read(key: _chavePerfil);
      if (bruto == null) return null;
      final json = jsonDecode(bruto);
      if (json is! Map<String, Object?>) return null;
      return PerfilAutenticado.fromJson(json);
    } on Object {
      // Cofre ilegível é tratado como "sem sessão": pede login de novo, em vez
      // de travar o app.
      return null;
    }
  }

  @override
  Future<Result<PerfilAutenticado>> entrar() async {
    if (!disponivel) {
      return const Err(AuthError('Login não está configurado nesta versão.'));
    }

    try {
      await _garantirInicializado();
      final conta = await GoogleSignIn.instance.authenticate();

      final perfil = PerfilAutenticado(
        id: conta.id,
        email: conta.email,
        nome: conta.displayName,
        fotoUrl: conta.photoUrl,
      );

      await _cofre.write(key: _chavePerfil, value: jsonEncode(perfil.toJson()));
      return Ok(perfil);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const Err(AuthError('Entrada cancelada.'));
      }
      return Err(AuthError('Não foi possível entrar: ${e.description ?? e.code}'));
    } on Object catch (e) {
      return Err(AuthError('Não foi possível entrar: $e'));
    }
  }

  @override
  Future<void> sair() async {
    // Apaga a sessão local primeiro: mesmo que a chamada ao Google falhe por
    // falta de rede, o "sair" precisa valer.
    try {
      await _cofre.delete(key: _chavePerfil);
    } on Object {
      // Ignorado de propósito.
    }
    try {
      await _garantirInicializado();
      await GoogleSignIn.instance.signOut();
    } on Object {
      // Sair do provedor é melhor-esforço.
    }
  }
}
