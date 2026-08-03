import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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

  AppLanguage _fromLang = languages.firstWhere((l) => l.code == 'en');
  AppLanguage _toLang = languages.firstWhere((l) => l.code == 'ar');

  @override
  void initState() {
    super.initState();
    final tts = Provider.of<TtsService>(context, listen: false);
    final speech = Provider.of<SpeechService>(context, listen: false);
    tts.initialize();
    speech.initialize();
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
    final speech = Provider.of<SpeechService>(context, listen: false);

    if (_isListening) {
      setState(() => _isListening = false);
      speech.stopListening();
      await Future.delayed(const Duration(milliseconds: 200));
      final text = speech.currentText;
      if (text.trim().isNotEmpty) {
        await _translateAndAdd(text);
      }
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
      await Future.delayed(const Duration(milliseconds: 600));
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
  Color get _cardAlt =>
      _isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey.shade100;
  Color get _textPrimary => _isDarkMode ? Colors.white : Colors.black87;
  Color get _textSecondary =>
      _isDarkMode ? Colors.white54 : Colors.grey.shade500;
  Color get _border =>
      _isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;

  @override
  Widget build(BuildContext context) {
    final speech = context.watch<SpeechService>();
    final translation = context.watch<TranslationService>();
    bool isListening = _isListening;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(translation),
            _buildLanguageSelector(),
            if (_messages.isEmpty && !_isListening && !_isVoiceMode)
              Expanded(child: _buildTextInputArea())
            else ...[
              if (_messages.isEmpty && !_isListening)
                _buildMicButtonArea()
              else
                _buildCompactMic(),
              if (_isListening && speech.currentText.isNotEmpty)
                _buildLivePreview(),
              Expanded(child: _buildMessagesList()),
              if (_isVoiceMode && _messages.isNotEmpty) _buildBottomMicBar(),
              if (!_isVoiceMode && _messages.isNotEmpty)
                _buildBottomTextInput(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TranslationService translation) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
            child: const Center(
                child: Text('ک',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                          text: 'Kalam ',
                          style: TextStyle(
                              color: _textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                      TextSpan(
                          text: 'كلام',
                          style:
                              TextStyle(color: _textSecondary, fontSize: 14)),
                    ],
                  ),
                ),
                Text('Voice Translator',
                    style: TextStyle(color: _textSecondary, fontSize: 11)),
              ],
            ),
          ),
          _buildModeToggle(),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _showSettings,
            child:
                Icon(Icons.settings_outlined, color: _textSecondary, size: 22),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? Colors.green.withOpacity(0.15)
                  : Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                        color: Colors.green, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(
                    translation.isTranslating
                        ? 'Translating...'
                        : _isListening
                            ? 'Listening...'
                            : 'Ready',
                    style: const TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeButton(Icons.mic, 'Voice', true),
          _modeButton(Icons.text_fields, 'Text', false),
        ],
      ),
    );
  }

  Widget _modeButton(IconData icon, String label, bool isVoice) {
    final active = isVoice ? _isVoiceMode : !_isVoiceMode;
    return GestureDetector(
      onTap: () => setState(() => _isVoiceMode = isVoice),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? _accent : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? Colors.white : Colors.grey),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: active ? Colors.white : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _langButton(_fromLang, (lang) => setState(() => _fromLang = lang)),
          GestureDetector(
            onTap: _swapLanguages,
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
              child: const Center(
                  child: Icon(Icons.swap_horiz, color: Colors.white, size: 18)),
            ),
          ),
          _langButton(_toLang, (lang) => setState(() => _toLang = lang)),
        ],
      ),
    );
  }

  Widget _langButton(AppLanguage lang, Function(AppLanguage) onSelect) {
    return Expanded(
      child: GestureDetector(
        onTap: () => LanguageBottomSheet.show(context, lang, onSelect),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border)),
          child: Row(
            children: [
              Text(lang.flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(lang.nativeName,
                    style: TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
              Icon(Icons.keyboard_arrow_down, color: _textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMicButtonArea() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _onMicTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _isListening ? Colors.redAccent : _accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? Colors.redAccent : _accent)
                        .withOpacity(0.3),
                    blurRadius: _isListening ? 25 : 15,
                    spreadRadius: _isListening ? 4 : 2,
                  ),
                ],
              ),
              child: Icon(_isListening ? Icons.stop : Icons.mic,
                  color: Colors.white, size: 42),
            ),
          ),
          const SizedBox(height: 14),
          Text(_isListening ? 'Listening...' : 'Tap the mic to start speaking',
              style: TextStyle(color: _textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCompactMic() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(child: Container()),
          Text(_isListening ? 'Listening...' : '',
              style: TextStyle(color: _textSecondary, fontSize: 12)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _onMicTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isListening ? 56 : 48,
              height: _isListening ? 56 : 48,
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
                  color: Colors.white, size: _isListening ? 26 : 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomMicBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _card, boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
      ]),
      child: Row(
        children: [
          Expanded(
            child: Text('${_messages.length} translations',
                style: TextStyle(color: _textSecondary, fontSize: 12)),
          ),
          GestureDetector(
            onTap: _onMicTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isListening ? 56 : 48,
              height: _isListening ? 56 : 48,
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
                  color: Colors.white, size: _isListening ? 26 : 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTextInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: _card, boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
      ]),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: _isDarkMode ? _cardAlt : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _border)),
              child: TextField(
                controller: _textController,
                style: TextStyle(color: _textPrimary, fontSize: 14),
                decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Type to translate...',
                    hintStyle: TextStyle(color: _textSecondary)),
                onSubmitted: (_) => _translateText(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _translateText,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
              child: const Center(
                  child: Icon(Icons.send, color: Colors.white, size: 20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputArea() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.text_fields,
                size: 50, color: _textSecondary.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text('Type text to translate',
                style: TextStyle(color: _textSecondary, fontSize: 15)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border)),
              child: TextField(
                controller: _textController,
                style: TextStyle(color: _textPrimary, fontSize: 16),
                decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter text here...',
                    hintStyle: TextStyle(color: _textSecondary)),
                onSubmitted: (_) => _translateText(),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _translateText,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                    color: _accent, borderRadius: BorderRadius.circular(24)),
                child: const Text('Translate',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePreview() {
    final speech = Provider.of<SpeechService>(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _accent.withOpacity(0.5))),
      child: Row(
        children: [
          SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: _accent)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(speech.currentText,
                  style: TextStyle(
                      color: _textPrimary,
                      fontSize: 14,
                      fontStyle: FontStyle.italic))),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) return const SizedBox.shrink();
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      itemCount: _messages.length,
      itemBuilder: (context, index) =>
          _buildTranslationCard(_messages[index], index),
    );
  }

  Widget _buildTranslationCard(ChatMessage msg, int index) {
    final time =
        '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: _card,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border.all(color: _border)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(_fromLang.flag,
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(msg.originalLang,
                              style: TextStyle(
                                  color: _accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text(time,
                              style: TextStyle(
                                  color: _textSecondary.withOpacity(0.6),
                                  fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(msg.originalText,
                          style: TextStyle(color: _textPrimary, fontSize: 15)),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                    onTap: () => _deleteMessage(index),
                    child: Icon(Icons.delete_outline,
                        color: _textSecondary.withOpacity(0.5), size: 18)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: _cardAlt,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                      color: _accent.withOpacity(0.15), shape: BoxShape.circle),
                  child: Center(
                      child: Text(_toLang.flag,
                          style: const TextStyle(fontSize: 14))),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(msg.translatedLang,
                          style: TextStyle(
                              color: _accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(msg.translatedText,
                          style: TextStyle(
                              color: _textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    _actionIcon(
                        Icons.volume_up, _accent, () => _replayMessage(msg)),
                    _actionIcon(Icons.copy, _textSecondary,
                        () => _copyText(msg.translatedText)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2))),
                const Text('Settings',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: _isDarkMode,
                  onChanged: (val) {
                    setState(() => _isDarkMode = val);
                    setSheet(() {});
                  },
                  secondary:
                      Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode),
                ),
                SwitchListTile(
                  title: const Text('Voice Mode'),
                  subtitle: const Text('Switch between voice and text input'),
                  value: _isVoiceMode,
                  onChanged: (val) {
                    setState(() => _isVoiceMode = val);
                    setSheet(() {});
                  },
                  secondary: const Icon(Icons.mic),
                ),
                const SizedBox(height: 10),
                Text('Kalam v1.0 | Made with love',
                    style: TextStyle(color: _textSecondary, fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }
}
