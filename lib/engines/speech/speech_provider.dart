/// Contrato de síntese de voz.
///
/// O núcleo de comunicação fala com esta interface, nunca com uma engine
/// concreta. Hoje existe apenas [NativeTtsProvider], que roda 100% offline no
/// dispositivo. Amanhã um `ElevenLabsProvider` pode entrar ao lado dele — com
/// consentimento explícito e cache local — sem que uma linha do domínio ou da
/// UI mude.
///
/// A decisão de manter a voz offline no MVP não é só de prazo: as frases de uma
/// criança revelam condição de saúde, e enviá-las a uma API externa significa
/// tratar dado pessoal sensível (LGPD art. 11) de titular criança (art. 14).
library;

import 'package:gigio/core/result/result.dart';

abstract interface class SpeechProvider {
  /// Nome legível, exibido nas configurações.
  String get name;

  /// Se a engine funciona sem rede. O Gigio prioriza providers offline: um app
  /// de comunicação não pode emudecer porque a internet caiu.
  bool get worksOffline;

  Future<Result<void>> initialize();

  /// Fala [text]. Interrompe qualquer fala em andamento — quando a criança toca
  /// um novo botão, ela quer dizer aquilo, não esperar a frase anterior acabar.
  Future<Result<void>> speak(String text);

  Future<Result<void>> stop();

  /// Vozes disponíveis para escolha do cuidador.
  Future<List<SpeechVoice>> availableVoices();

  Future<Result<void>> setVoice(SpeechVoice voice);

  /// Velocidade da fala, de 0.0 a 1.0.
  Future<Result<void>> setRate(double rate);

  Future<Result<void>> setPitch(double pitch);

  Future<void> dispose();
}

class SpeechVoice {
  const SpeechVoice({required this.id, required this.name, required this.locale});

  final String id;
  final String name;
  final String locale;

  bool get isBrazilianPortuguese =>
      locale.toLowerCase().replaceAll('_', '-').startsWith('pt-br');

  @override
  bool operator ==(Object other) =>
      other is SpeechVoice && other.id == id && other.locale == locale;

  @override
  int get hashCode => Object.hash(id, locale);

  @override
  String toString() => 'SpeechVoice($name, $locale)';
}
