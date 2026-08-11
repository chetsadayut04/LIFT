import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/database/profile_dao.dart';
import '../../core/database/weight_log_dao.dart';
import '../../core/database/set_dao.dart';
import '../../features/auth/auth_provider.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AiChatState {
  final bool isLoading;
  final List<ChatMessage> messages;

  const AiChatState({
    this.isLoading = false,
    this.messages = const [],
  });

  AiChatState copyWith({
    bool? isLoading,
    List<ChatMessage>? messages,
  }) =>
      AiChatState(
        isLoading: isLoading ?? this.isLoading,
        messages: messages ?? this.messages,
      );
}

class AiChatNotifier extends StateNotifier<AiChatState> {
  final Ref _ref;
  final _supabase = Supabase.instance.client;

  AiChatNotifier(this._ref) : super(const AiChatState()) {
    _init();
  }

  void _init() {
    final user = _ref.read(authProvider);
    final greeting = user != null
        ? "สวัสดีครับ! ผมคือ LIFT AI โค้ชส่วนตัวของคุณ ยินดีที่ได้คุยด้วยครับ มีอะไรที่ผมสามารถช่วยแนะนำเกี่ยวกับการออกกำลังกาย โภชนาการ หรือวิเคราะห์สถิติวันนี้ไหมครับ?"
        : "Hello! I am LIFT AI, your personal coach. How can I help you today with your fitness journey?";
    
    state = AiChatState(
      messages: [
        ChatMessage(text: greeting, isUser: false, timestamp: DateTime.now()),
      ],
    );
  }

  void refreshContext() {
    // Context is gathered dynamically on every sendMessage call, 
    // so no explicit refresh needed here.
  }

  Future<void> sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final user = _ref.read(authProvider);
    if (user == null) return;

    final userMessage = ChatMessage(
      text: cleanText,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      isLoading: true,
      messages: [...state.messages, userMessage],
    );

    try {
      // 1. Gather context dynamically to ensure it is always fresh
      final profile = await ProfileDao().getProfile(user.id);
      final weightLogs = await WeightLogDao().getAll();
      final exercisePrs = await SetDao().getAllExercisePrs();

      final heightVal = profile?.height?.toStringAsFixed(1) ?? 'Not set';
      
      final weightHistoryStr = weightLogs.isNotEmpty
          ? weightLogs
                .map((l) => "${l.weightKg.toStringAsFixed(1)} kg (${DateTime.fromMillisecondsSinceEpoch(l.loggedAt).toLocal().toString().split(' ').first})")
                .join(', ')
          : 'No logs recorded yet';

      final prsStr = exercisePrs.isNotEmpty
          ? exercisePrs
                .map((pr) => "${pr.name}: PR ${pr.prKg.toStringAsFixed(1)} kg x ${pr.prReps} reps")
                .join('\n')
          : 'No PR records yet';

      final contextStr = """
The user profile and stats context:
- Height: $heightVal cm
- Weight History Logs (newest first): $weightHistoryStr
- Personal Records (PRs) in workouts:
$prsStr
""";

      // 2. Invoke the Supabase Edge Function
      final response = await _supabase.functions.invoke(
        'ai-coach',
        body: {
          'message': cleanText,
          'context': contextStr,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final responseText = data['reply'] as String? ?? "ขออภัยด้วยครับ ผมเกิดข้อผิดพลาดในการประมวลผลคำตอบ";

      final aiMessage = ChatMessage(
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        isLoading: false,
        messages: [...state.messages, aiMessage],
      );
    } catch (e) {
      final errorMessage = ChatMessage(
        text: "เกิดข้อผิดพลาดในการเชื่อมต่อโค้ช AI: $e\nกรุณาตรวจสอบว่าเซิร์ฟเวอร์ Edge Function ทำงานปกติและตั้งค่า GEMINI_API_KEY เรียบร้อยแล้ว",
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        isLoading: false,
        messages: [...state.messages, errorMessage],
      );
    }
  }
}

final aiChatProvider = StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
  return AiChatNotifier(ref);
});
