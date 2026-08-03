import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/language.dart';
import '../services/speech_service.dart';
import '../services/translation_service.dart';
import '../services/tts_service.dart';
import '../widgets/language_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  bool _isListening = false;
  bool _isDarkMode = true;
  bool _isVoiceMode = true;
  bool _permissionGranted = false;

  AppLanguage _fromLang = languages.firstWhere((l) => l.code == 'en');
  AppLanguage _toLang = languages.firstWhere((l) => l.code == 'ar');

  @override
  void initState() {
    super.initState();
    _requestPermission();
    final tts = Provider.of<TtsService>(context, listen: false);
    final speech = Provider.of<SpeechService>(context, listen: false);
    tts.initialize();
    speech.initialize();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.microphone.request();
    setState(() => _permissionGranted = status.isGranted);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _onMicTap() async {
    if (!_permissionGranted) {
      await _requestPermission();
      return;
    }
    final speech = Provider.of<SpeechService>(context, listen: false);
    if (_isListening) {
      setState(() => _isListening = false);
      speech.stopListening();
      await Future.delayed(const Duration(milliseconds: 300));
      final text = speech.currentText;
      if (text.trim().isNotEmpty) await _translateAndAdd(text);
    } else {
      setState(() => _isListening = true);
      speech.startListening('A');
    }
  }

  Future<void> _translateText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    await _translateAndAdd(text);
  }

  Future<void> _translateAndAdd(String text) async {
    final translation = Provider.of<TranslationService>(context, listen: false);
    final tts = Provider.of<TtsService>(context, listen: false);
    final translated =
        await translation.translate(text, _fromLang.code, _toLang.code);
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(
        originalText: text,
        translatedText: translated,
        originalLang: _fromLang.nativeName,
        translatedLang: _toLang.nativeName,
        isPersonA: true,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      await tts.speak(translated, _toLang.ttsCode);
      while (tts.isSpeaking) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
      }
    }
  }

  void _swapLanguages() {
    setState(() {
      final temp = _fromLang;
      _fromLang = _toLang;
      _toLang = temp;
    });
  }

  void _replayMessage(ChatMessage msg) {
    final tts = Provider.of<TtsService>(context, listen: false);
    tts.speak(msg.translatedText,
        msg.isPersonA ? _toLang.ttsCode : _fromLang.ttsCode);
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied!'), duration: Duration(seconds: 1)),
    );
  }

  void _deleteMessage(int index) {
    setState(() => _messages.removeAt(index));
  }

  Color get _accent => const Color(0xFF1ABC9C);
  Color get _bg => _isDarkMode ? const Color(0xFF121212) : Colors.grey.shade50;
  Color get _card => _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _card2 =>
      _isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade100;
  Color get _txt1 => _isDarkMode ? Colors.white : Colors.black87;
  Color get _txt2 => _isDarkMode ? Colors.white60 : Colors.grey.shade600;
  Color get _brd => _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300;

  @override
  Widget build(BuildContext context) {
    final speech = context.watch<SpeechService>();
    final translation = context.watch<TranslationService>();
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(translation),
            _langSelector(),
            if (_messages.isEmpty && !_isListening && !_isVoiceMode)
              Expanded(child: _textOnlyMode())
            else if (_messages.isEmpty && !_isListening)
              Expanded(child: _bigMicArea())
            else ...[
              _smallMicRow(speech),
              Expanded(child: _messageList()),
              _bottomBar(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(TranslationService t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
                color: Color(0xFF1ABC9C), shape: BoxShape.circle),
            child: const Center(
                child: Text('ک',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kalam كلام',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Voice Translator', style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: Colors.green, shape: BoxShape.circle)),
                const SizedBox(width: 3),
                Text(
                    t.isTranslating
                        ? 'Translating...'
                        : _isListening
                            ? 'Listening...'
                            : 'Ready',
                    style: const TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showSettings,
            child: const Icon(Icons.settings_outlined,
                color: Colors.white54, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _langSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Expanded(
              child:
                  _langCard(_fromLang, (l) => setState(() => _fromLang = l))),
          GestureDetector(
            onTap: _swapLanguages,
            child: Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                  color: Color(0xFF1ABC9C), shape: BoxShape.circle),
              child: const Center(
                  child: Icon(Icons.swap_horiz, color: Colors.white, size: 14)),
            ),
          ),
          Expanded(
              child: _langCard(_toLang, (l) => setState(() => _toLang = l))),
        ],
      ),
    );
  }

  Widget _langCard(AppLanguage lang, Function(AppLanguage) onSel) {
    return GestureDetector(
      onTap: () => LanguageBottomSheet.show(context, lang, onSel),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _brd)),
        child: Row(
          children: [
            Text(lang.flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Expanded(
                child: Text(lang.nativeName,
                    style: TextStyle(
                        color: _txt1,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis)),
            Icon(Icons.keyboard_arrow_down, color: _txt2, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _bigMicArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _modeBtn(Icons.mic, 'Voice', true),
              const SizedBox(width: 8),
              _modeBtn(Icons.text_fields, 'Text', false),
            ],
          ),
        ),
        const SizedBox(height: 30),
        GestureDetector(
          onTap: _onMicTap,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _isListening ? Colors.redAccent : _accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: (_isListening ? Colors.redAccent : _accent)
                        .withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 3)
              ],
            ),
            child: Icon(_isListening ? Icons.stop : Icons.mic,
                color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 10),
        Text(_isListening ? 'Listening...' : 'Tap the mic to start speaking',
            style: TextStyle(color: _txt2, fontSize: 12)),
      ],
    );
  }

  Widget _modeBtn(IconData icon, String label, bool isVoice) {
    final active = isVoice ? _isVoiceMode : !_isVoiceMode;
    return GestureDetector(
      onTap: () => setState(() => _isVoiceMode = isVoice),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _accent : _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? _accent : _brd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: active ? Colors.white : _txt2),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: active ? Colors.white : _txt2,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _smallMicRow(SpeechService speech) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          if (_isListening && speech.currentText.isNotEmpty)
            Expanded(
                child: Text(speech.currentText,
                    style: TextStyle(
                        color: _txt1,
                        fontSize: 13,
                        fontStyle: FontStyle.italic)))
          else
            const Spacer(),
          if (_isListening)
            const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF1ABC9C))),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _onMicTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isListening ? Colors.redAccent : _accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: (_isListening ? Colors.redAccent : _accent)
                          .withOpacity(0.3),
                      blurRadius: 10)
                ],
              ),
              child: Icon(_isListening ? Icons.stop : Icons.mic,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageList() {
    if (_messages.isEmpty) return const SizedBox.shrink();
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      itemCount: _messages.length,
      itemBuilder: (context, i) => _msgCard(_messages[i], i),
    );
  }

  Widget _msgCard(ChatMessage msg, int i) {
    final time =
        '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _brd),
      ),
      child: Column(
        children: [
          // Source text
          Container(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_fromLang.flag, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(msg.originalLang,
                              style: TextStyle(
                                  color: _accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text(time,
                              style: TextStyle(color: _txt2, fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(msg.originalText,
                          style: TextStyle(color: _txt1, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                    onTap: () => _deleteMessage(i),
                    child: Icon(Icons.delete_outline, color: _txt2, size: 16)),
              ],
            ),
          ),
          // Translated text
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: _card2,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(10))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                      color: _accent.withOpacity(0.15), shape: BoxShape.circle),
                  child: Center(
                      child: Text(_toLang.flag,
                          style: const TextStyle(fontSize: 12))),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(msg.translatedLang,
                          style: TextStyle(
                              color: _accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(msg.translatedText,
                          style: TextStyle(
                              color: _txt1,
                              fontSize: 16,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                GestureDetector(
                    onTap: () => _replayMessage(msg),
                    child: Icon(Icons.volume_up, color: _accent, size: 20)),
                const SizedBox(width: 4),
                GestureDetector(
                    onTap: () => _copyText(msg.translatedText),
                    child: Icon(Icons.copy, color: _txt2, size: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: _card, border: Border(top: BorderSide(color: _brd))),
        child: Row(
          children: [
            if (!_isVoiceMode)
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: _card2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _brd)),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          style: TextStyle(color: _txt1, fontSize: 13),
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Type...',
                              hintStyle: TextStyle(color: _txt2)),
                          onSubmitted: (_) => _translateText(),
                        ),
                      ),
                      GestureDetector(
                          onTap: _translateText,
                          child: const Icon(Icons.send,
                              color: Color(0xFF1ABC9C), size: 18)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                  child: Text('${_messages.length} translations',
                      style: TextStyle(color: _txt2, fontSize: 11))),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _onMicTap,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isListening ? Colors.redAccent : _accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: (_isListening ? Colors.redAccent : _accent)
                            .withOpacity(0.3),
                        blurRadius: 10)
                  ],
                ),
                child: Icon(_isListening ? Icons.stop : Icons.mic,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textOnlyMode() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _modeBtn(Icons.mic, 'Voice', true),
              const SizedBox(width: 8),
              _modeBtn(Icons.text_fields, 'Text', false),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _brd)),
            child: TextField(
              controller: _textController,
              style: TextStyle(color: _txt1, fontSize: 15),
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter text to translate...',
                  hintStyle: TextStyle(color: _txt2)),
              onSubmitted: (_) => _translateText(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _translateText,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            decoration: const BoxDecoration(
                color: Color(0xFF1ABC9C),
                borderRadius: BorderRadius.circular(20)),
            child: const Text('Translate',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, set) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade500,
                        borderRadius: BorderRadius.circular(2))),
                Text('Settings',
                    style: TextStyle(
                        color: _txt1,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text('Dark Mode', style: TextStyle(color: _txt1)),
                  value: _isDarkMode,
                  onChanged: (v) {
                    setState(() => _isDarkMode = v);
                    set(() {});
                  },
                  secondary: Icon(
                      _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: _accent),
                ),
                SwitchListTile(
                  title: Text('Voice Mode', style: TextStyle(color: _txt1)),
                  subtitle: Text('Switch voice / text input',
                      style: TextStyle(color: _txt2, fontSize: 12)),
                  value: _isVoiceMode,
                  onChanged: (v) {
                    setState(() => _isVoiceMode = v);
                    set(() {});
                  },
                  secondary: const Icon(Icons.mic, color: Color(0xFF1ABC9C)),
                ),
                const SizedBox(height: 8),
                Text('Kalam v1.0',
                    style: TextStyle(color: _txt2, fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );
  }
}
