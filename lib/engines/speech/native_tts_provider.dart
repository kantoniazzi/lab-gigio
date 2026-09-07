/// Síntese de voz usando a engine nativa do sistema operacional.
///
/// Funciona offline no iOS, Android e (via Web Speech API) no Safari do iPad.
/// É a única engine do MVP, por escolha: zero rede, zero custo, zero latência
/// e zero dado saindo do dispositivo.
library;

import 'package:flutter_tts/flutter_tts.dart';
import 'package:gigio/core/errors/app_error.dart';
import 'package:gigio/core/result/result.dart';
import 'package:gigio/engines/speech/speech_provider.dart';

class NativeTtsProvider implements SpeechProvider {
  NativeTtsProvider({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  static const _preferredLocale = 'pt-BR';

  final FlutterTts _tts;
  bool _initialized = false;

  @override
  String get name => 'Voz do dispositivo';

  @override
  bool get worksOffline => true;

  @override
  Future<Result<void>> initialize() async {
    if (_initialized) return const Ok(null);
    try {
      await _tts.setLanguage(_preferredLocale);
      await _tts.setSpeechRate(_platformDefaultRate);
      await _tts.setPitch(1);
      await _tts.setVolume(1);

      // No iOS, sem isto, a fala é cortada quando outro áudio toca — e a fala
      // do app precisa ter prioridade sobre música de fundo.
      await _tts.setSharedInstance(true);

      _initialized = true;
      return const Ok(null);
    } on Object catch (e) {
      return Err(SpeechError('Não foi possível iniciar a voz do dispositivo: $e'));
    }
  }

  /// O `flutter_tts` interpreta a escala de velocidade de forma diferente em
  /// cada plataforma: no iOS 0.5 já é a velocidade natural, enquanto no Android
  /// e na web 0.5 soa arrastado.
  double get _platformDefaultRate => 0.5;

  @override
  Future<Result<void>> speak(String text) async {
    if (text.trim().isEmpty) return const Ok(null);

    final init = await initialize();
    if (init.isErr) return init;

    try {
      // Interrompe a fala anterior: quem toca um novo botão quer dizer aquilo
      // agora, não entrar numa fila.
      await _tts.stop();
      await _tts.speak(text);
      return const Ok(null);
    } on Object catch (e) {
      return Err(SpeechError('Não foi possível falar: $e'));
    }
  }

  @override
  Future<Result<void>> stop() async {
    try {
      await _tts.stop();
      return const Ok(null);
    } on Object catch (e) {
      return Err(SpeechError('Não foi possível interromper a fala: $e'));
    }
  }

  @override
  Future<List<SpeechVoice>> availableVoices() async {
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) return const [];

      final voices = <SpeechVoice>[];
      for (final entry in raw) {
        if (entry is! Map) continue;
        final name = entry['name']?.toString();
        final locale = entry['locale']?.toString();
        if (name == null || locale == null) continue;
        voices.add(SpeechVoice(id: name, name: name, locale: locale));
      }

      // Vozes pt-BR primeiro: são as únicas úteis aqui, e o cuidador não
      // deveria ter que garimpar numa lista de dezenas de idiomas.
      voices.sort((a, b) {
        if (a.isBrazilianPortuguese == b.isBrazilianPortuguese) {
          return a.name.compareTo(b.name);
        }
        return a.isBrazilianPortuguese ? -1 : 1;
      });
      return voices;
    } on Object {
      return const [];
    }
  }

  @override
  Future<Result<void>> setVoice(SpeechVoice voice) async {
    try {
      await _tts.setVoice({'name': voice.id, 'locale': voice.locale});
      return const Ok(null);
    } on Object catch (e) {
      return Err(SpeechError('Não foi possível trocar a voz: $e'));
    }
  }

  @override
  Future<Result<void>> setRate(double rate) async {
    try {
      await _tts.setSpeechRate(rate.clamp(0.0, 1.0));
      return const Ok(null);
    } on Object catch (e) {
      return Err(SpeechError('Não foi possível ajustar a velocidade: $e'));
    }
  }

  @override
  Future<Result<void>> setPitch(double pitch) async {
    try {
      await _tts.setPitch(pitch.clamp(0.5, 2.0));
      return const Ok(null);
    } on Object catch (e) {
      return Err(SpeechError('Não foi possível ajustar o tom: $e'));
    }
  }

  @override
  Future<void> dispose() async {
    await _tts.stop();
  }
}
