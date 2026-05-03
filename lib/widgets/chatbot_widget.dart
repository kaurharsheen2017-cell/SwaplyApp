import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../utils/app_theme.dart';

class _ChatMessage {
  final String text;
  final bool isBot;
  final DateTime time;
  _ChatMessage({required this.text, required this.isBot, required this.time});
}

class _FallbackBotEngine {
  static const List<Map<String, dynamic>> _rules = [
    {'keywords': ['hello','hi','hey','start','help'],
     'response': 'Hi! 👋 I\'m the Swaply assistant. Ask me anything about swapping, posts, ratings or the app!'},
    {'keywords': ['swap','how swap','how does swap','what is swap','swap work'],
     'response': '🔄 How a swap works:\n\n1. Browse the Feed\n2. Tap a post you like\n3. Hit "Start Chat & Swap"\n4. Agree on details in chat\n5. Tap "Confirm Swap"\n6. Complete the swap in real life\n7. Tap "Mark Done" and rate each other!'},
    {'keywords': ['create post','post skill','add post','new post','publish'],
     'response': '📝 To create a post:\n\n1. Tap the + button in the bottom nav\n2. Fill in title & description\n3. Add your skill\n4. Choose Barter or Custom\n5. Add tags\n6. Tap "Publish Skill Post"'},
    {'keywords': ['barter','exchange type','custom offer'],
     'response': '⇌ Exchange types:\n\n🔄 Barter — skill for skill\n🎁 Custom — money, treats, etc.'},
    {'keywords': ['chat','message','contact','talk'],
     'response': '💬 To start a chat:\n\n1. Open any post\n2. Tap "Start Chat & Swap"\n3. Send messages and images\n4. Once agreed, tap "Confirm Swap"'},
    {'keywords': ['rating','review','rate','stars','feedback'],
     'response': '⭐ After a swap completes, both parties rate 1-5 stars and leave a review. Ratings build your rep!'},
    {'keywords': ['profile','edit profile','username','bio','skills'],
     'response': '👤 Go to Profile tab → tap ✏️ → add bio, campus, skills → Save Changes.'},
    {'keywords': ['bookmark','save post','saved'],
     'response': '🔖 Tap the bookmark icon on any post. View saved posts in Profile → Bookmarks.'},
    {'keywords': ['leaderboard','top users','rank','ranking'],
     'response': '🏆 The leaderboard ranks users by swaps & ratings. Access it from your Profile screen.'},
    {'keywords': ['explore','search','find skill','discover'],
     'response': '🔍 Explore tab: search skills, tap popular tags, filter by Barter or Custom.'},
    {'keywords': ['notification','alert','notify'],
     'response': '🔔 Tap the bell icon on the Feed screen to see all notifications.'},
    {'keywords': ['confirm','confirm swap','deal','agree'],
     'response': '🤝 In a chat, agree on details then tap "Confirm Swap" in the header. When done, tap "Mark Done".'},
  ];

  static String respond(String input) {
    final lower = input.toLowerCase().trim();
    for (final rule in _rules) {
      for (final kw in rule['keywords'] as List<String>) {
        if (lower.contains(kw)) return rule['response'] as String;
      }
    }
    return "🤔 Try asking:\n• \"How do I swap?\"\n• \"How do I create a post?\"\n• \"How do ratings work?\"\n• \"What is barter?\"";
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ChatbotFab  — floating action button that opens the chat dialog
// ─────────────────────────────────────────────────────────────────────────────
class ChatbotFab extends StatelessWidget {
  const ChatbotFab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    return GestureDetector(
      onTap: () => showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Chatbot',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => const _ChatbotDialog(),
        transitionBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1), end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      child: Container(
        width: 54, height: 54,
        decoration: BoxDecoration(
          color: primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.38),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 26),
      ),
    ).animate().scale(delay: 800.ms, curve: Curves.elasticOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _ChatbotDialog  — full chat sheet, theme-aware
// ─────────────────────────────────────────────────────────────────────────────
class _ChatbotDialog extends StatefulWidget {
  const _ChatbotDialog();
  @override
  State<_ChatbotDialog> createState() => _ChatbotDialogState();
}

class _ChatbotDialogState extends State<_ChatbotDialog> {
  final _ctrl        = TextEditingController();
  final _scrollCtrl  = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping     = false;

  final _quickReplies = [
    'How do I swap?', 'Create a post',
    'How do ratings work?', 'What is barter?', 'Open requests',
  ];

  static const _apiKey = 'YOUR_GEMINI_API_KEY';
  ChatSession? _chatSession;

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      text: 'Hi! 👋 I\'m your AI Swaply assistant.\n\nHow can I help you today?',
      isBot: true, time: DateTime.now(),
    ));
    if (_apiKey != 'YOUR_GEMINI_API_KEY') {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
        systemInstruction: Content.system(
          'You are the Swaply Assistant. Swaply is a platform where '
          'university students barter skills or offer custom trades. '
          'Answer app questions and general knowledge questions. Be friendly and concise.',
        ),
      );
      _chatSession = model.startChat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose(); _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _ctrl.clear();
    setState(() {
      _messages.add(_ChatMessage(
          text: text.trim(), isBot: false, time: DateTime.now()));
      _isTyping = true;
    });
    _scrollToBottom();
    _getResponse(text.trim());
  }

  Future<void> _getResponse(String text) async {
    if (_chatSession == null) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
            text: _FallbackBotEngine.respond(text),
            isBot: true, time: DateTime.now()));
      });
      _scrollToBottom();
      return;
    }
    try {
      final resp = await _chatSession!.sendMessage(Content.text(text));
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
            text: resp.text ?? 'Sorry, no response.', isBot: true,
            time: DateTime.now()));
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
            text: 'Oops, something went wrong. Check your connection.',
            isBot: true, time: DateTime.now()));
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final sheetBg     = isDark ? AppColors.darkCardBg    : Colors.white;
    final inputBg     = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final borderTop   = isDark ? AppColors.darkBorder    : AppColors.divider;
    final chipBorder  = isDark ? AppColors.darkBorder    : AppColors.border;
    final textPri     = isDark ? AppColors.darkTextPrimary  : AppColors.textPrimary;
    final textLt      = isDark ? AppColors.darkTextLight    : AppColors.textLight;
    final primary     = isDark ? AppColors.darkPrimary      : AppColors.primary;
    final bubbleBg    = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.40 : 0.15),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(children: [
            // ── Header ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: const BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.xxl),
                  topRight: Radius.circular(AppRadius.xxl),
                ),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Swaply Assistant',
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.white, fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      Text('Ask me anything about the app',
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
            ),

            // ── Messages ─────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (_, i) {
                  if (_isTyping && i == _messages.length) {
                    return _buildTypingIndicator(bubbleBg);
                  }
                  return _buildMessage(
                      _messages[i], textPri, bubbleBg);
                },
              ),
            ),

            // ── Quick reply chips ─────────────────────────────────────────
            if (_messages.length <= 2)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _quickReplies.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _sendMessage(_quickReplies[i]),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                            border: Border.all(color: chipBorder),
                          ),
                          child: Text(_quickReplies[i],
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: primary)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Input bar ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: sheetBg,
                border: Border(top: BorderSide(color: borderTop, width: 1)),
              ),
              child: Row(children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.plusJakartaSans(
                          color: textPri, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Ask something...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                            color: textLt, fontSize: 13),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: _sendMessage,
                      maxLines: 3, minLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_ctrl.text),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildMessage(_ChatMessage msg, Color textPri, Color bubbleBg) {
    return Padding(
      padding: EdgeInsets.only(
          left: msg.isBot ? 0 : 40,
          right: msg.isBot ? 40 : 0,
          bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (msg.isBot) ...[
            Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                gradient: AppColors.accentGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 14),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: msg.isBot ? null : AppColors.primaryGradient,
                color: msg.isBot ? bubbleBg : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(msg.isBot ? 4 : 16),
                  bottomRight: Radius.circular(msg.isBot ? 16 : 4),
                ),
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, height: 1.5,
                  color: msg.isBot ? textPri : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildTypingIndicator(Color bubbleBg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          margin: const EdgeInsets.only(right: 8),
          decoration: const BoxDecoration(
              gradient: AppColors.accentGradient, shape: BoxShape.circle),
          child: const Icon(Icons.smart_toy_rounded,
              color: Colors.white, size: 14),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: bubbleBg, borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) => Container(
              margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
              child: const _TypingDot(),
            )),
          ),
        ),
      ]),
    ).animate().fadeIn();
  }
}

class _TypingDot extends StatefulWidget {
  const _TypingDot();
  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: -6)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 7, height: 7,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkTextLight : AppColors.textLight,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}