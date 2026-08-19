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
    final accent = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).cardTheme.color ?? const Color(0xFF151815);
    
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final textMuted = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    final chips = lang == AppLanguage.th
        ? [
            "แนะนำโปรแกรม 4 วัน",
            "เทคนิค Bench Press",
            "อาหารสร้างกล้าม",
          ]
        : [
            "Suggest 4-day program",
            "Bench Press technique",
            "Muscle building diet",
          ];

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Custom Header matching Figma exactly
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '🤖',
                      style: TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang == AppLanguage.th ? 'LIFT AI Coach' : 'LIFT AI Coach',
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFF2F5EF),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              lang == AppLanguage.th ? 'ออนไลน์' : 'Online',
                              style: GoogleFonts.sarabun(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: textMuted),
                    tooltip: lang == AppLanguage.th ? 'ลบประวัติแชท' : 'Clear Chat History',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(lang == AppLanguage.th ? 'ลบประวัติแชท?' : 'Clear Chat History?'),
                          content: Text(
                            lang == AppLanguage.th
                                ? 'ต้องการลบประวัติการสนทนาทั้งหมดใน AI Coach หรือไม่?'
                                : 'Are you sure you want to clear all conversation history?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(lang == AppLanguage.th ? 'ยกเลิก' : 'Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFFF5A3C),
                              ),
                              child: Text(lang == AppLanguage.th ? 'ลบ' : 'Clear'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && mounted) {
                        await ref.read(aiChatProvider.notifier).clearHistory();
                      }
                    },
                  ),
                ],
              ),
            ),
            // Messages area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            
            // Suggestion chips matching Figma
            if (state.messages.length <= 1)
              Container(
                height: 42,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: chips.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final text = chips[index];
                    return GestureDetector(
                      onTap: () => _sendMessage(text),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121A15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          text,
                          style: GoogleFonts.sarabun(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            // Input bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF080808).withValues(alpha: 0.98),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      style: GoogleFonts.sarabun(
                        color: const Color(0xFFFFFFFF),
                        fontSize: 14,
                      ),
                      onChanged: (val) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: lang == AppLanguage.th
                            ? 'ถามเรื่องการฝึกซ้อม...'
                            : 'Ask anything about fitness...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF16221B),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF223326),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Send button
                  GestureDetector(
                    onTap: () => _sendMessage(_inputController.text),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _inputController.text.trim().isNotEmpty
                            ? Theme.of(context).colorScheme.primary
                            : const Color(0xFF1A241E),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        state.isLoading ? Icons.hourglass_empty : Icons.arrow_upward,
                        color: _inputController.text.trim().isNotEmpty
                            ? const Color(0xFF000000)
                            : const Color(0xFF94A3B8),
                        size: 20,
                      ),
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


    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text(
                '🤖',
                style: TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: msg.isUser
                    ? Theme.of(context).colorScheme.primary
                    : const Color(0xFF121A15),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: msg.isUser ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: msg.isUser ? const Radius.circular(4) : const Radius.circular(18),
                ),
                border: msg.isUser
                    ? null
                    : Border.all(
                        color: const Color(0xFF223326),
                        width: 1,
                      ),
              ),
              child: MarkdownBody(
                data: msg.text,
                styleSheet: MarkdownStyleSheet(
                  p: GoogleFonts.sarabun(
                    color: msg.isUser ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
                    fontSize: 14,
                    height: 1.6,
                  ),
                  h1: GoogleFonts.barlowCondensed(
                    color: msg.isUser ? const Color(0xFF000000) : Theme.of(context).colorScheme.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  h2: GoogleFonts.barlowCondensed(
                    color: msg.isUser ? const Color(0xFF000000) : Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  h3: GoogleFonts.barlowCondensed(
                    color: msg.isUser ? const Color(0xFF000000) : Theme.of(context).colorScheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  listBullet: TextStyle(
                    color: msg.isUser ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
                  ),
                  strong: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: msg.isUser ? const Color(0xFF000000) : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
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
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text(
              '🤖',
              style: TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF121A15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(
                color: const Color(0xFF223326),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return SizedBox(
      width: 7,
      height: 7,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
