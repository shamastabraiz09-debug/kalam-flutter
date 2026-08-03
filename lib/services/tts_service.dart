import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    await _flutterTts.awaitSpeakCompletion(true);
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setVolume(1.0);
    _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });

    _flutterTts.setErrorHandler((msg) {
      debugPrint('TTS Error: $msg');
      _isSpeaking = false;
      notifyListeners();
    });
  }

  Future<void> speak(String text, String languageCode) async {
    if (text.trim().isEmpty) return;

    await _flutterTts.stop();

    // Find matching voice for the language
    var voices = await _flutterTts.getVoices;
    String? selectedVoice;

    for (var voice in voices) {
      if (voice['locale'].toString().startsWith(languageCode)) {
        selectedVoice = voice['locale'].toString();
        break;
      }
    }

    if (selectedVoice != null) {
      await _flutterTts.setLanguage(selectedVoice);
    } else {
      await _flutterTts.setLanguage(languageCode);
    }

    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
    notifyListeners();
  }
}