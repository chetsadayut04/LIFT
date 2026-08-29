import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { th, en }

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.th) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final langStr = prefs.getString('app_language') ?? 'th';
    state = langStr == 'en' ? AppLanguage.en : AppLanguage.th;
  }

  Future<void> setLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    state = language;
    await prefs.setString(
      'app_language',
      language == AppLanguage.en ? 'en' : 'th',
    );
  }

  void toggle() {
    setLanguage(state == AppLanguage.th ? AppLanguage.en : AppLanguage.th);
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>((
  ref,
) {
  return LanguageNotifier();
});

extension AppLanguageX on AppLanguage {
  String tr(String key) {
    return _translations[key]?[this] ?? key;
  }
}

// Complete central translations dictionary
const Map<String, Map<AppLanguage, String>> _translations = {
  // Navigation Tabs
  'nav_home': {AppLanguage.th: 'หน้าหลัก', AppLanguage.en: 'Home'},
  'nav_history': {AppLanguage.th: 'ประวัติ', AppLanguage.en: 'History'},
  'nav_stats': {AppLanguage.th: 'สถิติ', AppLanguage.en: 'Stats'},
  'nav_ai': {AppLanguage.th: 'โค้ช AI', AppLanguage.en: 'AI Coach'},
  'nav_profile': {AppLanguage.th: 'โปรไฟล์', AppLanguage.en: 'Profile'},

  // Profile Screen
  'profile_title': {AppLanguage.th: 'โปรไฟล์', AppLanguage.en: 'Profile'},
  'settings_section': {
    AppLanguage.th: 'ตั้งค่าระบบ',
    AppLanguage.en: 'System Settings',
  },
  'weight_unit_title': {
    AppLanguage.th: 'หน่วยน้ำหนัก',
    AppLanguage.en: 'Weight Unit',
  },
  'weight_unit_lbs': {
    AppLanguage.th: 'กำลังใช้: ปอนด์ (lbs)',
    AppLanguage.en: 'Current: Pounds (lbs)',
  },
  'weight_unit_kg': {
    AppLanguage.th: 'กำลังใช้: กิโลกรัม (kg)',
    AppLanguage.en: 'Current: Kilograms (kg)',
  },
  'language_title': {
    AppLanguage.th: 'ภาษาแอปพลิเคชัน',
    AppLanguage.en: 'App Language',
  },
  'language_desc_th': {
    AppLanguage.th: 'กำลังใช้: ภาษาไทย (TH)',
    AppLanguage.en: 'Current: Thai (TH)',
  },
  'language_desc_en': {
    AppLanguage.th: 'กำลังใช้: ภาษาอังกฤษ (EN)',
    AppLanguage.en: 'Current: English (EN)',
  },
  'theme_title': {AppLanguage.th: 'ธีมหน้าจอ', AppLanguage.en: 'Screen Theme'},
  'theme_desc_dark': {
    AppLanguage.th: 'กำลังใช้: โหมดมืด (Dark)',
    AppLanguage.en: 'Current: Dark Mode',
  },
  'theme_desc_light': {
    AppLanguage.th: 'กำลังใช้: โหมดสว่าง (Light)',
    AppLanguage.en: 'Current: Light Mode',
  },
  'general_info_section': {
    AppLanguage.th: 'ข้อมูลทั่วไป',
    AppLanguage.en: 'General Info',
  },
  'feedback_title': {
    AppLanguage.th: 'ส่งคำแนะนำ / รายงานปัญหา',
    AppLanguage.en: 'Send Feedback / Bug Report',
  },
  'app_version': {
    AppLanguage.th: 'เวอร์ชันแอปพลิเคชัน',
    AppLanguage.en: 'App Version',
  },
  'delete_account': {
    AppLanguage.th: 'ลบบัญชีผู้ใช้งาน',
    AppLanguage.en: 'Delete Account',
  },
  'sign_out': {AppLanguage.th: 'ออกจากระบบ', AppLanguage.en: 'Sign Out'},
  'delete_confirm_title': {
    AppLanguage.th: 'ลบบัญชี?',
    AppLanguage.en: 'Delete Account?',
  },
  'delete_confirm_desc': {
    AppLanguage.th:
        'ลบประวัติการฝึก ข้อมูลร่างกาย และบัญชีทั้งหมดถาวร? การกระทำนี้ไม่สามารถย้อนกลับได้',
    AppLanguage.en:
        'Delete all training history, body metrics and your account permanently? This cannot be undone.',
  },
  'btn_cancel': {AppLanguage.th: 'ยกเลิก', AppLanguage.en: 'Cancel'},
  'btn_delete': {AppLanguage.th: 'ลบ', AppLanguage.en: 'Delete'},
  'btn_save': {AppLanguage.th: 'บันทึก', AppLanguage.en: 'Save'},
  'btn_close': {AppLanguage.th: 'ปิด', AppLanguage.en: 'Close'},
  'saved_success': {
    AppLanguage.th: 'บันทึกการเปลี่ยนแปลงสำเร็จ!',
    AppLanguage.en: 'Saved successfully!',
  },
  'body_weight': {
    AppLanguage.th: 'น้ำหนักร่างกาย',
    AppLanguage.en: 'Body Weight',
  },
  'body_height': {AppLanguage.th: 'ส่วนสูง', AppLanguage.en: 'Height'},
  'btn_view_history': {
    AppLanguage.th: 'ดูประวัติ',
    AppLanguage.en: 'View History',
  },
  'weight_history_title': {
    AppLanguage.th: 'ประวัติน้ำหนักตัว',
    AppLanguage.en: 'Weight History',
  },
  'weight_history_empty': {
    AppLanguage.th: 'ยังไม่มีบันทึกน้ำหนักตัว',
    AppLanguage.en: 'No weight logs recorded yet.',
  },
  'btn_delete_confirm': {
    AppLanguage.th: 'ลบข้อมูลนี้',
    AppLanguage.en: 'Delete Entry',
  },
  'btn_delete_desc': {
    AppLanguage.th: 'คุณแน่ใจหรือไม่ว่าต้องการลบประวัติน้ำหนักนี้?',
    AppLanguage.en: 'Are you sure you want to delete this weight log?',
  },

  // Home Screen
  'home_ready': {AppLanguage.th: 'พร้อมแล้ว?', AppLanguage.en: 'Ready?'},
  'home_start': {
    AppLanguage.th: 'เริ่ม Workout',
    AppLanguage.en: 'Start Workout',
  },
  'home_continue': {AppLanguage.th: 'ทำต่อ →', AppLanguage.en: 'Continue →'},
  'home_finish': {AppLanguage.th: 'เสร็จ', AppLanguage.en: 'Finish'},
  'home_view_summary': {AppLanguage.th: 'ดูสรุป', AppLanguage.en: 'Summary'},
  'home_edit': {AppLanguage.th: 'แก้ไข', AppLanguage.en: 'Edit'},
  'home_today': {AppLanguage.th: 'วันนี้', AppLanguage.en: 'Today'},
  'home_not_started': {
    AppLanguage.th: 'ยังไม่ได้เริ่มวันนี้',
    AppLanguage.en: 'Not started today',
  },
  'home_warming_up': {
    AppLanguage.th: 'กำลังอุ่นเครื่อง...',
    AppLanguage.en: 'Warming up...',
  },
  'home_vs_prev': {
    AppLanguage.th: ' จากครั้งก่อน',
    AppLanguage.en: ' vs previous',
  },
  'dialog_program_title': {
    AppLanguage.th: 'ชื่อโปรแกรมวันนี้',
    AppLanguage.en: 'Workout Program Name',
  },
  'dialog_program_hint': {
    AppLanguage.th: 'เช่น Push Day, Leg Day...',
    AppLanguage.en: 'e.g. Push Day, Leg Day...',
  },
  'dialog_program_past': {
    AppLanguage.th: 'โปรแกรมที่เคยทำ',
    AppLanguage.en: 'Past Programs',
  },
  'btn_skip': {AppLanguage.th: 'ข้าม', AppLanguage.en: 'Skip'},
  'btn_start': {AppLanguage.th: 'เริ่ม', AppLanguage.en: 'Start'},
  'home_streak': {
    AppLanguage.th: 'วันติดต่อกัน',
    AppLanguage.en: 'days streak',
  },
  'home_finished_today_alert': {
    AppLanguage.th: 'ออกกำลังกายเสร็จสิ้นแล้ววันนี้ 💪',
    AppLanguage.en: 'Workout finished for today! 💪',
  },

  // Workout / Exercise Card
  'workout_no_exercises': {
    AppLanguage.th: 'ยังไม่มีท่า',
    AppLanguage.en: 'No exercises yet',
  },
  'workout_add_exercise_hint': {
    AppLanguage.th: 'กด + เพื่อเพิ่มท่าออกกำลังกาย',
    AppLanguage.en: 'Tap + to add exercises',
  },
  'workout_add_exercise': {
    AppLanguage.th: 'เพิ่มท่า',
    AppLanguage.en: 'Add Exercise',
  },
  'dialog_delete_exercise': {
    AppLanguage.th: 'ลบท่า?',
    AppLanguage.en: 'Delete Exercise?',
  },
  'dialog_delete_exercise_desc': {
    AppLanguage.th: 'ลบ และ sets ทั้งหมด?',
    AppLanguage.en: 'Delete and all sets?',
  },
  'dialog_rename_exercise': {
    AppLanguage.th: 'เปลี่ยนชื่อท่า',
    AppLanguage.en: 'Rename Exercise',
  },
  'btn_add_set': {AppLanguage.th: 'เพิ่มเซ็ต', AppLanguage.en: 'Add Set'},
  'label_weight': {AppLanguage.th: 'น้ำหนัก', AppLanguage.en: 'Weight'},
  'label_reps': {AppLanguage.th: 'จำนวน', AppLanguage.en: 'Reps'},
  'label_rest': {AppLanguage.th: 'พัก', AppLanguage.en: 'Rest'},
  'dialog_target_title': {AppLanguage.th: 'เป้าหมาย', AppLanguage.en: 'Target'},

  // History Screen
  'history_no_records': {
    AppLanguage.th: 'ยังไม่มีประวัติ',
    AppLanguage.en: 'No history yet',
  },
  'dialog_delete_session': {
    AppLanguage.th: 'ลบ session?',
    AppLanguage.en: 'Delete session?',
  },
  'dialog_delete_session_desc': {
    AppLanguage.th: 'ลบ workout วันที่ ',
    AppLanguage.en: 'Delete workout on ',
  },
  'history_detail_title': {
    AppLanguage.th: 'รายละเอียด',
    AppLanguage.en: 'Workout Details',
  },
  'history_prev_sets': {
    AppLanguage.th: 'ครั้งก่อน',
    AppLanguage.en: 'Previous',
  },
  'history_active_badge': {
    AppLanguage.th: 'กำลังเล่น',
    AppLanguage.en: 'Active',
  },

  // Stats Screen
  'stats_weekly_vol': {
    AppLanguage.th: 'ปริมาณการฝึกรายสัปดาห์',
    AppLanguage.en: 'Weekly Training Volume',
  },
  'stats_weekly_sets': {
    AppLanguage.th: 'จำนวนเซ็ตรายสัปดาห์',
    AppLanguage.en: 'Weekly Total Sets',
  },
  'stats_exercise_prog': {
    AppLanguage.th: 'สถิติรายท่า',
    AppLanguage.en: 'Exercise Progression',
  },
  'stats_exercise_list': {
    AppLanguage.th: 'รายชื่อท่าออกกำลังกาย',
    AppLanguage.en: 'Exercise List',
  },
  'stats_volume': {
    AppLanguage.th: 'ปริมาณการฝึก (Volume)',
    AppLanguage.en: 'Volume',
  },
  'stats_max_weight': {
    AppLanguage.th: 'น้ำหนักยกสูงสุด (Max Weight)',
    AppLanguage.en: 'Max Weight',
  },
  'stats_all_time_pr': {
    AppLanguage.th: 'ประวัติการฝึกสูงสุด',
    AppLanguage.en: 'All-Time PRs',
  },
  'stats_this_week': {
    AppLanguage.th: 'สัปดาห์นี้',
    AppLanguage.en: 'This Week',
  },
  'stats_last_week': {
    AppLanguage.th: 'สัปดาห์ก่อน',
    AppLanguage.en: 'Last Week',
  },
  'stats_sets_this_week': {
    AppLanguage.th: 'เซ็ตสัปดาห์นี้',
    AppLanguage.en: 'Sets This Week',
  },
  'stats_sets_last_week': {
    AppLanguage.th: 'เซ็ตสัปดาห์ก่อน',
    AppLanguage.en: 'Sets Last Week',
  },
};
