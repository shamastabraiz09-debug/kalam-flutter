import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TranslationService extends ChangeNotifier {
  bool _isTranslating = false;
  String _error = '';

  bool get isTranslating => _isTranslating;
  String get error => _error;

  Future<String> translate(String text, String fromLang, String toLang) async {
    if (text.trim().isEmpty) return '';

    _isTranslating = true;
    _error = '';
    notifyListeners();

    try {
      String result = await _googleTranslate(text, fromLang, toLang);
      if (result.isEmpty) {
        result = await _myMemoryTranslate(text, fromLang, toLang);
      }
      _isTranslating = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isTranslating = false;
      notifyListeners();
      return 'Translation failed: $_error';
    }
  }

  Future<String> _googleTranslate(String text, String from, String to) async {
    try {
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single'
            '?client=gtx&sl=$from&tl=$to&dt=t&q=${Uri.encodeComponent(text)}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final buffer = StringBuffer();
        for (var segment in data[0]) {
          if (segment[0] != null) {
            buffer.write(segment[0]);
          }
        }
        return buffer.toString();
      }
      return '';
    } catch (e) {
      debugPrint('Google Translate failed: $e');
      return '';
    }
  }

  Future<String> _myMemoryTranslate(String text, String from, String to) async {
    try {
      final url = Uri.parse(
        'https://api.mymemory.translated.net/get'
            '?q=${Uri.encodeComponent(text)}&langpair=$from|$to',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['responseData']['translatedText'] ?? '';
      }
      return 'Translation failed';
    } catch (e) {
      return 'Translation failed: $e';
    }
  }
}