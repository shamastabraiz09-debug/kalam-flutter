import 'package:flutter/material.dart';
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
  bool _personASpeaking = false;
  bool _personBSpeaking = false;

  AppLanguage _personALang = languages.firstWhere((l) => l.code == 'ur');
  AppLanguage _personBLang = languages.firstWhere((l) => l.code == 'ar');

  @override
  void initState() {
    super.initState();
    final tts = Provider.of<TtsService>(context, listen: false);
    final speech = Provider.of<SpeechService>(context, listen: false);
    tts.initialize();
    speech.initialize();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onPersonAComplete(String text) async {
    if (text.trim().isEmpty) return;
    final speech = Provider.of<SpeechService>(context, listen: false);
    final translation = Provider.of<TranslationService>(context, listen: false);
    final tts = Provider.of<TtsService>(context, listen: false);

    setState(() => _personASpeaking = false);
    speech.stopListening();

    final translated = await translation.translate(text, _personALang.code, _personBLang.code);

    setState(() {
      _messages.add(ChatMessage(
        originalText: text,
        translatedText: translated,
        originalLang: _personALang.nativeName,
        translatedLang: _personBLang.nativeName,
        isPersonA: true,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
    tts.speak(translated, _personBLang.ttsCode);
  }

  void _onPersonBComplete(String text) async {
    if (text.trim().isEmpty) return;
    final speech = Provider.of<SpeechService>(context, listen: false);
    final translation = Provider.of<TranslationService>(context, listen: false);
    final tts = Provider.of<TtsService>(context, listen: false);

    setState(() => _personBSpeaking = false);
    speech.stopListening();

    final translated = await translation.translate(text, _personBLang.code, _personALang.code);

    setState(() {
      _messages.add(ChatMessage(
        originalText: text,
        translatedText: translated,
        originalLang: _personBLang.nativeName,
        translatedLang: _personALang.nativeName,
        isPersonA: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
    tts.speak(translated, _personALang.ttsCode);
  }

  void _togglePersonA() {
    final speech = Provider.of<SpeechService>(context, listen: false);
    if (_personBSpeaking) {
      setState(() => _personBSpeaking = false);
      speech.stopListening();
    }
    setState(() => _personASpeaking = !_personASpeaking);
    if (_personASpeaking) {
      speech.startListening('A');
    } else {
      speech.stopListening();
      if (speech.currentText.trim().isNotEmpty) {
        _onPersonAComplete(speech.currentText);
      }
    }
  }

  void _togglePersonB() {
    final speech = Provider.of<SpeechService>(context, listen: false);
    if (_personASpeaking) {
      setState(() => _personASpeaking = false);
      speech.stopListening();
    }
    setState(() => _personBSpeaking = !_personBSpeaking);
    if (_personBSpeaking) {
      speech.startListening('B');
    } else {
      speech.stopListening();
      if (speech.currentText.trim().isNotEmpty) {
        _onPersonBComplete(speech.currentText);
      }
    }
  }

  void _swapLanguages() {
    setState(() {
      final temp = _personALang;
      _personALang = _personBLang;
      _personBLang = temp;
    });
  }

  void _replayMessage(ChatMessage msg) {
    final tts = Provider.of<TtsService>(context, listen: false);
    tts.speak(msg.translatedText, msg.isPersonA ? _personBLang.ttsCode : _personALang.ttsCode);
  }

  @override
  Widget build(BuildContext context) {
    final speech = context.watch<SpeechService>();
    final translation = context.watch<TranslationService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('کلام - Kalam', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Language selector bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => LanguageBottomSheet.show(context, _personALang, (lang) {
                      setState(() => _personALang = lang);
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_personALang.flag, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Text('Person A: ${_personALang.nativeName}',
                              style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _swapLanguages,
                  icon: Icon(Icons.swap_horiz, color: Colors.grey.shade600),
                  tooltip: 'Swap Languages',
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => LanguageBottomSheet.show(context, _personBLang, (lang) {
                      setState(() => _personBLang = lang);
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_personBLang.flag, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Text('Person B: ${_personBLang.nativeName}',
                              style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.translate, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Tap a mic to start translating',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildChatBubble(msg);
                    },
                  ),
          ),

          // Live text preview
          if (speech.currentText.isNotEmpty && (_personASpeaking || _personBSpeaking))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: _personASpeaking ? Colors.green.shade100 : Colors.blue.shade100,
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _personASpeaking ? Colors.green : Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(speech.currentText,
                        style: TextStyle(
                          fontSize: 14,
                          color: _personASpeaking ? Colors.green.shade800 : Colors.blue.shade800,
                          fontStyle: FontStyle.italic,
                        )),
                  ),
                ],
              ),
            ),

          // Mic buttons area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Row(
              children: [
                // Person A mic
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _personBSpeaking || translation.isTranslating ? null : _togglePersonA,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _personASpeaking ? Colors.green : Colors.green.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: Icon(_personASpeaking ? Icons.mic : Icons.mic_none, size: 28),
                    label: const Text('Person A', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                // Person B mic
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _personASpeaking || translation.isTranslating ? null : _togglePersonB,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _personBSpeaking ? Colors.blue : Colors.blue.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: Icon(_personBSpeaking ? Icons.mic : Icons.mic_none, size: 28),
                    label: const Text('Person B', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    final isA = msg.isPersonA;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: isA ? Alignment.centerLeft : Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isA ? Colors.green.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isA ? const Radius.circular(4) : const Radius.circular(16),
                bottomRight: isA ? const Radius.circular(16) : const Radius.circular(4),
              ),
              border: Border.all(color: isA ? Colors.green.shade200 : Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(msg.originalText, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isA ? Colors.green.shade900 : Colors.blue.shade900)),
                const Divider(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(msg.translatedText, style: TextStyle(fontSize: 15, color: isA ? Colors.green.shade700 : Colors.blue.shade700)),
                    ),
                    IconButton(
                      onPressed: () => _replayMessage(msg),
                      icon: Icon(Icons.volume_up, size: 20, color: isA ? Colors.green.shade600 : Colors.blue.shade600),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${msg.originalLang} → ${msg.translatedLang}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}