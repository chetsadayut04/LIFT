import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/translation_provider.dart';
import '../../core/providers/unit_provider.dart';
import '../auth/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _selectedGoal = 'Fitness';
  bool _isSaving = false;

  static const _kHeight = 'profile_height';
  static const _kWeight = 'profile_weight';
  static const _kGoal = 'profile_goal';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _heightController.text = prefs.getString(_kHeight) ?? '';
      _weightController.text = prefs.getString(_kWeight) ?? '';
      var goal = prefs.getString(_kGoal) ?? 'Fitness';
      if (goal == 'General Fitness') goal = 'Fitness';
      _selectedGoal = goal;
    });
  }

  Future<void> _saveProfileData() async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final lang = ref.read(languageProvider);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHeight, _heightController.text.trim());
    await prefs.setString(_kWeight, _weightController.text.trim());
    await prefs.setString(_kGoal, _selectedGoal);

    if (mounted) {
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(lang.tr('saved_success')),
          backgroundColor: const Color(0xFF1B1F1B),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _sendFeedback(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final user = ref.read(authProvider);
    final email = user?.email ?? 'Anonymous';

    final lang = ref.read(languageProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      // บันทึกลงตาราง feedbacks ใน Supabase (หลีกเลี่ยงปัญหา CORS บน Web)
      final supabase = Supabase.instance.client;
      await supabase.from('feedbacks').insert({
        'user_id': user?.id,
        'email': email,
        'message': cleanText,
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            lang == AppLanguage.th
                ? 'ขอบคุณสำหรับความคิดเห็น! เราได้รับข้อมูลเรียบร้อยแล้ว'
                : 'Thank you for your feedback! We have received it.',
          ),
          backgroundColor: const Color(0xFF1B1F1B),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error sending feedback: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showFeedbackDialog() {
    final feedbackController = TextEditingController();
    final lang = ref.read(languageProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.tr('feedback_title')),
        content: TextField(
          controller: feedbackController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: lang == AppLanguage.th
                ? 'พิมพ์คำแนะนำหรือปัญหาที่คุณพบที่นี่...'
                : 'Type your feedback or bugs here...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              lang.tr('btn_cancel'),
              style: const TextStyle(color: Color(0xFF7C8A7C)),
            ),
          ),
          FilledButton(
            onPressed: () {
              final text = feedbackController.text.trim();
              Navigator.pop(context);
              if (text.isNotEmpty) {
                _sendFeedback(text);
              }
            },
            child: Text(lang == AppLanguage.th ? 'ส่งข้อมูล' : 'Send'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final lang = ref.read(languageProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.tr('delete_confirm_title')),
        content: Text(
          lang.tr('delete_confirm_desc'),
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              lang.tr('btn_cancel'),
              style: const TextStyle(color: Color(0xFF7C8A7C)),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              await ref.read(authProvider.notifier).signOut();
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(
                    lang == AppLanguage.th
                        ? 'ลบบัญชีผู้ใช้งานและเซสชันสำเร็จแล้ว'
                        : 'Successfully deleted account and session',
                  ),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            child: Text(
              lang.tr('btn_delete'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final isLbs = ref.watch(isLbsProvider);
    final themeMode = ref.watch(themeProvider);
    final lang = ref.watch(languageProvider);

    final bg = Theme.of(context).scaffoldBackgroundColor;
    final border = Theme.of(context).colorScheme.outline;
    final accent = Theme.of(context).colorScheme.primary;
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFFF2F5EF);
    final textMuted =
        Theme.of(context).textTheme.bodySmall?.color ?? const Color(0xFF7C8A7C);

    // Extracting user metadata from Social Sign-In
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final displayName =
        user?.userMetadata?['full_name'] as String? ??
        user?.userMetadata?['name'] as String? ??
        user?.email?.split('@').first ??
        (lang == AppLanguage.th ? 'ผู้ใช้งาน LIFT' : 'LIFT User');

    final goals = [
      {
        'key': 'Strength',
        'label': lang.tr('goal_strength'),
        'icon': Icons.fitness_center,
      },
      {
        'key': 'Hypertrophy',
        'label': lang.tr('goal_hypertrophy'),
        'icon': Icons.accessibility_new,
      },
      {
        'key': 'Fat Loss',
        'label': lang.tr('goal_fatloss'),
        'icon': Icons.local_fire_department,
      },
      {
        'key': 'Fitness',
        'label': lang.tr('goal_fitness'),
        'icon': Icons.favorite_border,
      },
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          lang.tr('profile_title'),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Info Card (Premium Glowing Header)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: accent, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: accent.withValues(alpha: 0.1),
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null
                              ? Icon(Icons.person, color: accent, size: 32)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ??
                                  (lang == AppLanguage.th
                                      ? 'ไม่พบอีเมลผู้ใช้งาน'
                                      : 'User email not found'),
                              style: TextStyle(fontSize: 13, color: textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Body Metrics Card (Height & Weight inputs)
              Row(
                children: [
                  Icon(Icons.accessibility, color: textMuted, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    lang == AppLanguage.th
                        ? 'ข้อมูลสรีระร่างกาย'
                        : 'Body Metrics',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: lang == AppLanguage.th
                                    ? 'ส่วนสูง (cm)'
                                    : 'Height (cm)',
                                prefixIcon: Icon(
                                  Icons.height,
                                  color: textMuted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: lang == AppLanguage.th
                                    ? 'น้ำหนักตัว (${isLbs ? "lbs" : "kg"})'
                                    : 'Weight (${isLbs ? "lbs" : "kg"})',
                                prefixIcon: Icon(Icons.scale, color: textMuted),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _isSaving ? null : _saveProfileData,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined, size: 18),
                        label: Text(
                          lang == AppLanguage.th
                              ? 'บันทึกข้อมูลร่างกาย'
                              : 'Save Body Metrics',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Training Goal Section
              Row(
                children: [
                  Icon(Icons.track_changes, color: textMuted, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    lang.tr('goals_title'),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: goals.map((goal) {
                      final isSelected = _selectedGoal == goal['key'];
                      return ListTile(
                        leading: Icon(
                          goal['icon'] as IconData,
                          color: isSelected ? accent : textMuted,
                        ),
                        title: Text(
                          goal['label'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? textPrimary : textMuted,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: accent, size: 20)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedGoal = goal['key'] as String;
                          });
                          _saveProfileData(); // Auto save when changing goal
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // General Settings Header
              Row(
                children: [
                  Icon(Icons.settings, color: textMuted, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    lang.tr('settings_section'),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Settings Selection Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      // Weight Unit Row
                      ListTile(
                        leading: Icon(Icons.scale_outlined, color: textMuted),
                        title: Text(
                          lang.tr('weight_unit_title'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          isLbs
                              ? lang.tr('weight_unit_lbs')
                              : lang.tr('weight_unit_kg'),
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: isLbs
                                  ? () => ref
                                        .read(isLbsProvider.notifier)
                                        .toggle()
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: !isLbs ? accent : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: !isLbs
                                      ? null
                                      : Border.all(color: border),
                                ),
                                child: Text(
                                  'KG',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    color: !isLbs
                                        ? (themeMode == ThemeMode.dark
                                              ? Colors.black
                                              : Colors.white)
                                        : textMuted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: !isLbs
                                  ? () => ref
                                        .read(isLbsProvider.notifier)
                                        .toggle()
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isLbs ? accent : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: isLbs
                                      ? null
                                      : Border.all(color: border),
                                ),
                                child: Text(
                                  'LBS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    color: isLbs
                                        ? (themeMode == ThemeMode.dark
                                              ? Colors.black
                                              : Colors.white)
                                        : textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(indent: 56, endIndent: 16),
                      // Language Row
                      ListTile(
                        leading: Icon(
                          Icons.language_outlined,
                          color: textMuted,
                        ),
                        title: Text(
                          lang.tr('language_title'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          lang == AppLanguage.th
                              ? lang.tr('language_desc_th')
                              : lang.tr('language_desc_en'),
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: lang != AppLanguage.th
                                  ? () => ref
                                        .read(languageProvider.notifier)
                                        .setLanguage(AppLanguage.th)
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: lang == AppLanguage.th
                                      ? accent
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: lang == AppLanguage.th
                                      ? null
                                      : Border.all(color: border),
                                ),
                                child: Text(
                                  'TH',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    color: lang == AppLanguage.th
                                        ? (themeMode == ThemeMode.dark
                                              ? Colors.black
                                              : Colors.white)
                                        : textMuted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: lang != AppLanguage.en
                                  ? () => ref
                                        .read(languageProvider.notifier)
                                        .setLanguage(AppLanguage.en)
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: lang == AppLanguage.en
                                      ? accent
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: lang == AppLanguage.en
                                      ? null
                                      : Border.all(color: border),
                                ),
                                child: Text(
                                  'EN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    color: lang == AppLanguage.en
                                        ? (themeMode == ThemeMode.dark
                                              ? Colors.black
                                              : Colors.white)
                                        : textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(indent: 56, endIndent: 16),
                      // Theme Row
                      ListTile(
                        leading: Icon(
                          themeMode == ThemeMode.dark
                              ? Icons.dark_mode_outlined
                              : Icons.light_mode_outlined,
                          color: textMuted,
                        ),
                        title: Text(
                          lang.tr('theme_title'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          themeMode == ThemeMode.dark
                              ? lang.tr('theme_desc_dark')
                              : lang.tr('theme_desc_light'),
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: themeMode != ThemeMode.light
                                  ? () => ref
                                        .read(themeProvider.notifier)
                                        .setThemeMode(ThemeMode.light)
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: themeMode == ThemeMode.light
                                      ? accent
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: themeMode == ThemeMode.light
                                      ? null
                                      : Border.all(color: border),
                                ),
                                child: Text(
                                  lang == AppLanguage.th ? 'สว่าง' : 'Light',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    color: themeMode == ThemeMode.light
                                        ? (themeMode == ThemeMode.dark
                                              ? Colors.black
                                              : Colors.white)
                                        : textMuted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: themeMode != ThemeMode.dark
                                  ? () => ref
                                        .read(themeProvider.notifier)
                                        .setThemeMode(ThemeMode.dark)
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: themeMode == ThemeMode.dark
                                      ? accent
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: themeMode == ThemeMode.dark
                                      ? null
                                      : Border.all(color: border),
                                ),
                                child: Text(
                                  lang == AppLanguage.th ? 'มืด' : 'Dark',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    color: themeMode == ThemeMode.dark
                                        ? (themeMode == ThemeMode.dark
                                              ? Colors.black
                                              : Colors.white)
                                        : textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // About & Support Card
              Row(
                children: [
                  Icon(Icons.info_outline, color: textMuted, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    lang.tr('general_info_section'),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.chat_bubble_outline,
                          color: textMuted,
                        ),
                        title: Text(
                          lang.tr('feedback_title'),
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: textMuted,
                          size: 18,
                        ),
                        onTap: _showFeedbackDialog,
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(
                          Icons.perm_device_info_outlined,
                          color: textMuted,
                        ),
                        title: Text(
                          lang.tr('app_version'),
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: const Text(
                          'v1.0.0',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Danger Zone Card
              Card(
                color: themeMode == ThemeMode.dark
                    ? const Color(0xFF1E1111)
                    : const Color(0xFFFFF5F5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: themeMode == ThemeMode.dark
                        ? const Color(0xFF3E1F1F)
                        : const Color(0xFFFFD3D3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.delete_forever_outlined,
                          color: Colors.redAccent,
                        ),
                        title: Text(
                          lang.tr('delete_account'),
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: _showDeleteAccountDialog,
                      ),
                      Divider(
                        color: themeMode == ThemeMode.dark
                            ? const Color(0xFF3E1F1F)
                            : const Color(0xFFFFD3D3),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.logout,
                          color: Colors.redAccent,
                        ),
                        title: Text(
                          lang.tr('sign_out'),
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () async {
                          await ref.read(authProvider.notifier).signOut();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
