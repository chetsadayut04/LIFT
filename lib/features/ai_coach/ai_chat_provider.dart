import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/database/ai_chat_message_dao.dart';
import '../../core/database/database_helper.dart';
import '../../core/database/profile_dao.dart';
import '../../core/database/routine_dao.dart';
import '../../core/database/set_dao.dart';
import '../../core/database/weight_log_dao.dart';
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
  final _dao = AiChatMessageDao();

  AiChatNotifier(this._ref) : super(const AiChatState()) {
    _init();
  }

  Future<void> _init() async {
    final stored = await _dao.getMessages();
    final user = _ref.read(authProvider);

    if (stored.isNotEmpty) {
      state = AiChatState(
        messages: stored
            .map((item) => ChatMessage(
                  text: item.text,
                  isUser: item.isUser,
                  timestamp: item.timestamp,
                ))
            .toList(),
      );
    } else {
      final greeting = user != null
          ? "สวัสดีครับ! ผมคือ LIFT AI โค้ชส่วนตัวของคุณ ยินดีที่ได้คุยด้วยครับ มีอะไรที่ผมสามารถช่วยแนะนำเกี่ยวกับการออกกำลังกาย โภชนาการ หรือวิเคราะห์สถิติวันนี้ไหมครับ?"
          : "Hello! I am LIFT AI, your personal coach. How can I help you today with your fitness journey?";

      final initialMsg = ChatMessage(text: greeting, isUser: false, timestamp: DateTime.now());
      state = AiChatState(messages: [initialMsg]);
      await _dao.insertMessage(
        uuid: generateUUID(),
        isUser: false,
        text: greeting,
        timestamp: initialMsg.timestamp,
      );
    }
  }

  void refreshContext() {
    // Context is gathered dynamically on every sendMessage call, 
    // so no explicit refresh needed here.
  }

  Future<void> clearHistory() async {
    await _dao.clearAll();
    final user = _ref.read(authProvider);
    final greeting = user != null
        ? "สวัสดีครับ! ผมคือ LIFT AI โค้ชส่วนตัวของคุณ มีอะไรเพิ่มเติมที่อยากสอบถามไหมครับ?"
        : "Hello! History cleared. How can I help you today?";

    final initialMsg = ChatMessage(text: greeting, isUser: false, timestamp: DateTime.now());
    state = AiChatState(messages: [initialMsg]);
    await _dao.insertMessage(
      uuid: generateUUID(),
      isUser: false,
      text: greeting,
      timestamp: initialMsg.timestamp,
    );
  }

  Future<void> sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final user = _ref.read(authProvider);
    if (user == null) return;

    final now = DateTime.now();
    final userMessage = ChatMessage(
      text: cleanText,
      isUser: true,
      timestamp: now,
    );

    await _dao.insertMessage(
      uuid: generateUUID(),
      isUser: true,
      text: cleanText,
      timestamp: now,
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

      final routineDao = RoutineDao();
      final routines = await routineDao.getRoutines();
      final List<String> routineSummaries = [];
      for (final r in routines) {
        if (r.id != null) {
          final exercises = await routineDao.getExercisesForRoutine(r.id!);
          final List<String> exDetails = [];
          for (final ex in exercises) {
            if (ex.id != null) {
              final sets = await routineDao.getSetsForExercise(ex.id!);
              final setSummary = sets.map((s) => "${s.weightKg}kg x ${s.reps}").join(', ');
              exDetails.add("  - ${ex.name}: [$setSummary]");
            } else {
              exDetails.add("  - ${ex.name}");
            }
          }
          routineSummaries.add("Routine '${r.name}':\n${exDetails.join('\n')}");
        }
      }

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

      final routinesStr = routineSummaries.isNotEmpty
          ? routineSummaries.join('\n\n')
          : 'No saved routines created yet';

      final contextStr = """
The user profile and stats context:
- Height: $heightVal cm
- Weight History Logs (newest first): $weightHistoryStr
- Personal Records (PRs) in workouts:
$prsStr

- User's Saved Workout Routines (ตารางการฝึก):
$routinesStr
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

      final aiTime = DateTime.now();
      final aiMessage = ChatMessage(
        text: responseText,
        isUser: false,
        timestamp: aiTime,
      );

      await _dao.insertMessage(
        uuid: generateUUID(),
        isUser: false,
        text: responseText,
        timestamp: aiTime,
      );

      state = state.copyWith(
        isLoading: false,
        messages: [...state.messages, aiMessage],
      );
    } catch (e) {
      final errTime = DateTime.now();
      final errStr = e.toString().toLowerCase();
      String userFriendlyMessage;

      if (errStr.contains("high demand") ||
          errStr.contains("429") ||
          errStr.contains("503") ||
          errStr.contains("overloaded") ||
          errStr.contains("temporarily unavailable")) {
        userFriendlyMessage =
            "ขณะนี้โมเดล AI กำลังมีผู้ใช้งานเป็นจำนวนมาก กรุณารอประมาณ 5-10 วินาที แล้วลองกดส่งใหม่อีกครั้งครับ";
      } else if (errStr.contains("gemini_api_key")) {
        userFriendlyMessage =
            "ยังไม่ได้ตั้งค่า GEMINI_API_KEY บนเซิร์ฟเวอร์ Edge Function กรุณาตรวจสอบ Environment Variable ใน Supabase";
      } else {
        userFriendlyMessage =
            "เกิดข้อผิดพลาดในการเชื่อมต่อโค้ช AI: $e\nกรุณาตรวจสอบว่าเซิร์ฟเวอร์ Edge Function ทำงานปกติและตั้งค่า GEMINI_API_KEY เรียบร้อยแล้ว";
      }

      final errorMessage = ChatMessage(
        text: userFriendlyMessage,
        isUser: false,
        timestamp: errTime,
      );

      await _dao.insertMessage(
        uuid: generateUUID(),
        isUser: false,
        text: errorMessage.text,
        timestamp: errTime,
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
