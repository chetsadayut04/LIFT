import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/translation_provider.dart';
import 'ai_chat_provider.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _inputController.clear();
    await ref.read(aiChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiChatProvider);
    final lang = ref.watch(languageProvider);
    
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final border = Theme.of(context).colorScheme.outline;
    final accent = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).cardTheme.color ?? const Color(0xFF151815);
    
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final textMuted = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    final chips = lang == AppLanguage.th
        ? [
            "วิเคราะห์ประวัติน้ำหนักของฉัน",
            "แนะนำโปรแกรมฝึกอกและหลังแขน",
            "อธิบายวิธีการทำท่า Squat ที่ถูกวิธี",
            "คำนวณ BMI และระดับความแข็งแรงปัจจุบัน",
          ]
        : [
            "Analyze my weight history",
            "Suggest a chest and triceps program",
            "Explain how to squat correctly",
            "Calculate my BMI and strength level",
          ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          lang.tr('nav_ai'),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: state.messages.length + (state.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.messages.length) {
                    return _buildThinkingBubble(context, accent, surface);
                  }

                  final msg = state.messages[index];
                  return _buildChatBubble(context, msg, accent, surface, textPrimary, textMuted);
                },
              ),
            ),
            
            if (state.messages.length <= 1)
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: chips.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final text = chips[index];
                    return ActionChip(
                      label: Text(
                        text,
                        style: TextStyle(
                          fontSize: 11,
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: surface,
                      side: BorderSide(color: border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onPressed: () => _sendMessage(text),
                    );
                  },
                ),
              ),

            const SizedBox(height: 8),
            const Divider(),
            
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      decoration: InputDecoration(
                        hintText: lang == AppLanguage.th
                            ? "พิมพ์ข้อความสอบถามที่นี่..."
                            : "Ask anything about fitness...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: accent, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: accent,
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.black, size: 18),
                      onPressed: () => _sendMessage(_inputController.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(
    BuildContext context,
    ChatMessage msg,
    Color accent,
    Color surface,
    Color textPrimary,
    Color textMuted,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alignment = msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    
    final bubbleColor = msg.isUser
        ? (isDark ? const Color(0xFF1E281F) : const Color(0xFFE4F0DE))
        : surface;

    final borderSide = msg.isUser
        ? BorderSide(color: accent.withValues(alpha: 0.3))
        : BorderSide(color: Theme.of(context).colorScheme.outline);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!msg.isUser) ...[
                CircleAvatar(
                  backgroundColor: accent.withValues(alpha: 0.16),
                  radius: 14,
                  child: Icon(Icons.smart_toy, color: accent, size: 16),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: msg.isUser ? const Radius.circular(16) : Radius.zero,
                      bottomRight: msg.isUser ? Radius.zero : const Radius.circular(16),
                    ),
                    border: Border.fromBorderSide(borderSide),
                  ),
                  child: MarkdownBody(
                    data: msg.text,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(color: textPrimary, fontSize: 14, height: 1.4, fontFamily: GoogleFonts.inter().fontFamily),
                      h1: GoogleFonts.spaceGrotesk(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold, height: 1.5),
                      h2: GoogleFonts.spaceGrotesk(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold, height: 1.5),
                      h3: GoogleFonts.spaceGrotesk(color: textPrimary, fontSize: 14, fontWeight: FontWeight.bold, height: 1.5),
                      listBullet: TextStyle(color: textPrimary, fontSize: 14),
                      strong: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              if (msg.isUser) ...[
                const SizedBox(width: 8),
                const CircleAvatar(
                  backgroundColor: Colors.grey,
                  radius: 14,
                  child: Icon(Icons.person, color: Colors.white, size: 16),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingBubble(BuildContext context, Color accent, Color surface) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: accent.withValues(alpha: 0.16),
            radius: 14,
            child: Icon(Icons.smart_toy, color: accent, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                ),
                const SizedBox(width: 12),
                Text(
                  ref.read(languageProvider) == AppLanguage.th
                      ? "กำลังคิด..."
                      : "Thinking...",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
