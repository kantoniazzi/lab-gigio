/// PIN do cuidador, que protege o modo de edição.
///
/// O PIN nunca é guardado em texto claro. Guardamos apenas um hash derivado com
/// PBKDF2-HMAC-SHA256 e um salt aleatório por dispositivo, dentro do
/// armazenamento seguro do sistema (Keychain no iOS, Keystore no Android).
///
/// Um PIN de 4 dígitos tem só 10 mil combinações, então nenhuma quantidade de
/// iterações o torna resistente a um atacante com acesso ao hash. O objetivo
/// aqui é outro e mais modesto — e vale ser honesto sobre isso: impedir que a
/// **criança** entre no editor por acidente e desconfigure o próprio board.
/// Não é um controle contra adversário com posse do aparelho. Para esse caso,
/// a proteção real é o Acesso Guiado do iPad, no nível do sistema.
///
/// LIMITAÇÃO NA WEB: no build web o `flutter_secure_storage` recai sobre o
/// armazenamento do navegador, que não tem equivalente ao Keychain. O PIN
/// continua hasheado, mas o isolamento é mais fraco que no app nativo.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gigio/core/errors/app_error.dart';
import 'package:gigio/core/result/result.dart';

class CaregiverPinService {
  CaregiverPinService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              // No Android o armazenamento já é cifrado com AES-GCM por padrão
              // desde a v11 do plugin, então não há opção a ajustar aqui.
              iOptions: IOSOptions(
                // `this_device` impede que o PIN viaje em backup do iCloud
                // para outro aparelho.
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  static const _hashKey = 'gigio_pin_hash';
  static const _saltKey = 'gigio_pin_salt';
  static const _iterations = 120000;
  static const _keyLengthBytes = 32;

  /// PIN usado quando o cuidador ainda não definiu um.
  ///
  /// Existe para que o app seja utilizável assim que instalado. As
  /// configurações mostram um aviso pedindo que seja trocado.
  static const defaultPin = '1234';

  final FlutterSecureStorage _storage;

  Future<bool> isConfigured() async =>
      await _storage.read(key: _hashKey) != null;

  Future<Result<void>> setPin(String pin) async {
    final normalized = pin.trim();
    if (normalized.length < 4 || !RegExp(r'^\d+$').hasMatch(normalized)) {
      return const Err(AuthError('O PIN precisa ter ao menos 4 dígitos numéricos.'));
    }

    try {
      final salt = _randomSalt();
      final hash = _derive(normalized, salt);

      await _storage.write(key: _saltKey, value: base64Encode(salt));
      await _storage.write(key: _hashKey, value: base64Encode(hash));
      return const Ok(null);
    } on Object catch (e) {
      return Err(AuthError('Não foi possível salvar o PIN: $e'));
    }
  }

  Future<bool> verify(String pin) async {
    final normalized = pin.trim();

    try {
      final storedHash = await _storage.read(key: _hashKey);
      final storedSalt = await _storage.read(key: _saltKey);

      if (storedHash == null || storedSalt == null) {
        // Ainda não configurado: aceita o PIN padrão para não travar o app
        // recém-instalado.
        return normalized == defaultPin;
      }

      final computed = _derive(normalized, base64Decode(storedSalt));
      return _constantTimeEquals(computed, base64Decode(storedHash));
    } on Object {
      return false;
    }
  }

  Future<void> reset() async {
    await _storage.delete(key: _hashKey);
    await _storage.delete(key: _saltKey);
  }

  Uint8List _randomSalt() {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(16, (_) => rng.nextInt(256)),
    );
  }

  /// PBKDF2-HMAC-SHA256.
  Uint8List _derive(String pin, List<int> salt) {
    final hmac = Hmac(sha256, utf8.encode(pin));
    final output = Uint8List(_keyLengthBytes);
    var offset = 0;
    var block = 1;

    while (offset < _keyLengthBytes) {
      // U1 = PRF(senha, salt || INT_32_BE(bloco))
      final blockIndex = Uint8List(4)
        ..buffer.asByteData().setUint32(0, block, Endian.big);
      var u = Uint8List.fromList(hmac.convert([...salt, ...blockIndex]).bytes);
      final acc = Uint8List.fromList(u);

      for (var i = 1; i < _iterations; i++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var j = 0; j < acc.length; j++) {
          acc[j] ^= u[j];
        }
      }

      final take = (_keyLengthBytes - offset).clamp(0, acc.length);
      output.setRange(offset, offset + take, acc);
      offset += take;
      block++;
    }

    return output;
  }

  /// Comparação em tempo constante, para não vazar informação por timing.
  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
