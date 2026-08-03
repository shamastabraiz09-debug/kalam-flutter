import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isAvailable = false;
  String _currentText = '';
  String _errorText = '';
  String _activePerson = ''; // 'A' or 'B'

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  String get currentText => _currentText;
  String get errorText => _errorText;
  String get activePerson => _activePerson;

  Future<void> initialize() async {
    _isAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' && _isListening) {
          _restartListening();
        }
      },
      onError: (error) {
        debugPrint('Speech error: $error');
        if (_isListening) {
          _restartListening();
        }
      },
    );
    _isInitialized = _isAvailable;
    notifyListeners();
  }

  Future<void> startListening(String person) async {
    if (!_isInitialized) {
      await initialize();
    }
    if (!_isAvailable) {
      _errorText = 'Speech not available on this device';
      notifyListeners();
      return;
    }

    _activePerson = person;
    _currentText = '';
    _isListening = true;
    _errorText = '';
    notifyListeners();

    await _speech.listen(
      onResult: (result) {
        _currentText = result.recognizedWords;
        notifyListeners();
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenMode: stt.ListenMode.dictation,
      cancelOnError: true,
      partialResults: true,
    );
  }

  Future<void> _restartListening() async {
    _isListening = false;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    if (_activePerson.isNotEmpty) {
      _isListening = true;
      notifyListeners();
      await _speech.listen(
        onResult: (result) {
          _currentText = result.recognizedWords;
          notifyListeners();
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenMode: stt.ListenMode.dictation,
        cancelOnError: true,
        partialResults: true,
      );
    }
  }

  Future<void> stopListening() async {
    _isListening = false;
    _activePerson = '';
    await _speech.stop();
    notifyListeners();
  }

  Future<void> disposeSpeech() async {
    await _speech.stop();
    _isListening = false;
    _activePerson = '';
  }
}