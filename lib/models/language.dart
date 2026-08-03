import 'package:flutter/material.dart';

class AppLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String ttsCode;
  final String flag;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.ttsCode,
    required this.flag,
  });
}

class ChatMessage {
  final String originalText;
  final String translatedText;
  final String originalLang;
  final String translatedLang;
  final bool isPersonA;
  final DateTime timestamp;

  ChatMessage({
    required this.originalText,
    required this.translatedText,
    required this.originalLang,
    required this.translatedLang,
    required this.isPersonA,
    required this.timestamp,
  });
}

const List<AppLanguage> languages = [
  AppLanguage(code: 'ur', name: 'Urdu', nativeName: 'اردو', ttsCode: 'ur-PK', flag: '🇵🇰'),
  AppLanguage(code: 'ar', name: 'Arabic', nativeName: 'العربية', ttsCode: 'ar-SA', flag: '🇸🇦'),
  AppLanguage(code: 'en', name: 'English', nativeName: 'English', ttsCode: 'en-US', flag: '🇺🇸'),
  AppLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', ttsCode: 'hi-IN', flag: '🇮🇳'),
  AppLanguage(code: 'bn', name: 'Bengali', nativeName: 'বাংলা', ttsCode: 'bn-IN', flag: '🇧🇩'),
  AppLanguage(code: 'es', name: 'Spanish', nativeName: 'Español', ttsCode: 'es-ES', flag: '🇪🇸'),
  AppLanguage(code: 'fr', name: 'French', nativeName: 'Français', ttsCode: 'fr-FR', flag: '🇫🇷'),
  AppLanguage(code: 'de', name: 'German', nativeName: 'Deutsch', ttsCode: 'de-DE', flag: '🇩🇪'),
  AppLanguage(code: 'tr', name: 'Turkish', nativeName: 'Türkçe', ttsCode: 'tr-TR', flag: '🇹🇷'),
  AppLanguage(code: 'zh', name: 'Chinese', nativeName: '中文', ttsCode: 'zh-CN', flag: '🇨🇳'),
  AppLanguage(code: 'ja', name: 'Japanese', nativeName: '日本語', ttsCode: 'ja-JP', flag: '🇯🇵'),
  AppLanguage(code: 'ko', name: 'Korean', nativeName: '한국어', ttsCode: 'ko-KR', flag: '🇰🇷'),
  AppLanguage(code: 'pt', name: 'Portuguese', nativeName: 'Português', ttsCode: 'pt-BR', flag: '🇧🇷'),
  AppLanguage(code: 'ru', name: 'Russian', nativeName: 'Русский', ttsCode: 'ru-RU', flag: '🇷🇺'),
  AppLanguage(code: 'it', name: 'Italian', nativeName: 'Italiano', ttsCode: 'it-IT', flag: '🇮🇹'),
  AppLanguage(code: 'nl', name: 'Dutch', nativeName: 'Nederlands', ttsCode: 'nl-NL', flag: '🇳🇱'),
  AppLanguage(code: 'pl', name: 'Polish', nativeName: 'Polski', ttsCode: 'pl-PL', flag: '🇵🇱'),
  AppLanguage(code: 'th', name: 'Thai', nativeName: 'ไทย', ttsCode: 'th-TH', flag: '🇹🇭'),
  AppLanguage(code: 'vi', name: 'Vietnamese', nativeName: 'Tiếng Việt', ttsCode: 'vi-VN', flag: '🇻🇳'),
  AppLanguage(code: 'fa', name: 'Persian', nativeName: 'فارسی', ttsCode: 'fa-IR', flag: '🇮🇷'),
  AppLanguage(code: 'ms', name: 'Malay', nativeName: 'Bahasa Melayu', ttsCode: 'ms-MY', flag: '🇲🇾'),
  AppLanguage(code: 'sw', name: 'Swahili', nativeName: 'Kiswahili', ttsCode: 'sw-KE', flag: '🇰🇪'),
  AppLanguage(code: 'id', name: 'Indonesian', nativeName: 'Bahasa Indonesia', ttsCode: 'id-ID', flag: '🇮🇩'),
];