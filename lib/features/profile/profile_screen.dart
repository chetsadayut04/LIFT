import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/profile.dart';
import '../../core/models/weight_log.dart';
import '../../core/database/profile_dao.dart';
import '../../core/database/weight_log_dao.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/translation_provider.dart';
import '../../core/providers/unit_provider.dart';
import '../auth/auth_provider.dart';
import '../stats/stats_screen.dart';
import '../workout/routines_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Profile? _profile;
  List<WeightLog> _weightLogs = [];
  final _profileDao = ProfileDao();
  final _weightLogDao = WeightLogDao();

  static const _kHeight = 'profile_height';
  static const _kWeight = 'profile_weight';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = ref.read(authProvider);
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final spHeight = prefs.getString(_kHeight);

    var profile = await _profileDao.getProfile(user.id);
    var logs = await _weightLogDao.getAll();

    // Migration bridge: SharedPreferences -> DB
    if (profile == null && spHeight != null) {
      final height = double.tryParse(spHeight);
      profile = Profile(
        id: user.id,
        height: height,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _profileDao.saveProfile(profile);

      final spWeight = prefs.getString(_kWeight);
      if (spWeight != null) {
        final w = double.tryParse(spWeight);
        if (w != null && w > 0) {
          await _weightLogDao.insert(w, DateTime.now().millisecondsSinceEpoch);
          logs = await _weightLogDao.getAll();
        }
      }

      await prefs.remove(_kHeight);
      await prefs.remove(_kWeight);
    }

    if (mounted) {
      setState(() {
        _profile = profile;
        _weightLogs = logs;
      });
    }
  }

  void _showEditHeightBottomSheet(double? currentHeight) {
    final controller = TextEditingController(
      text: currentHeight != null ? currentHeight.toStringAsFixed(1) : '',
    );
    final lang = ref.read(languageProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final border = Theme.of(context).colorScheme.outline;
        final bg = Theme.of(context).scaffoldBackgroundColor;
        final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border.all(color: border, width: 0.5),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang == AppLanguage.th ? 'แก้ไขส่วนสูง' : 'Edit Height',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: lang == AppLanguage.th ? 'ส่วนสูง (cm)' : 'Height (cm)',
                    prefixIcon: const Icon(Icons.height),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    final val = double.tryParse(controller.text.trim());
                    if (val != null && val > 0) {
                      final user = ref.read(authProvider);
                      if (user != null) {
                        final updatedProfile = Profile(
                          id: user.id,
                          height: val,
                          updatedAt: DateTime.now().millisecondsSinceEpoch,
                        );
                        await _profileDao.saveProfile(updatedProfile);
                        await _loadProfileData();
                      }
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(lang == AppLanguage.th ? 'บันทึก' : 'Save'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditWeightBottomSheet(double? currentWeightKg) {
    final isLbs = ref.read(isLbsProvider);
    final initialDisplay = currentWeightKg != null
        ? (isLbs ? currentWeightKg * kgToLbs : currentWeightKg)
        : null;
    final controller = TextEditingController(
      text: initialDisplay != null ? initialDisplay.toStringAsFixed(1) : '',
    );
    final lang = ref.read(languageProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final border = Theme.of(context).colorScheme.outline;
        final bg = Theme.of(context).scaffoldBackgroundColor;
        final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
        final unit = isLbs ? 'lbs' : 'kg';

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border.all(color: border, width: 0.5),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang == AppLanguage.th ? 'บันทึกน้ำหนักตัว' : 'Log Weight',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: lang == AppLanguage.th ? 'น้ำหนักตัว ($unit)' : 'Weight ($unit)',
                    prefixIcon: const Icon(Icons.scale),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    final val = double.tryParse(controller.text.trim());
                    if (val != null && val > 0) {
                      final weightKg = isLbs ? val * lbsToKg : val;
                      await _weightLogDao.insert(
                        weightKg,
                        DateTime.now().millisecondsSinceEpoch,
                      );
                      await _loadProfileData();
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(lang == AppLanguage.th ? 'บันทึก' : 'Save'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendFeedback(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final user = ref.read(authProvider);
    final email = user?.email ?? 'Anonymous';

    final lang = ref.read(languageProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
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
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFFF2F5EF);
    final textMuted = Theme.of(context).textTheme.bodySmall?.color ?? const Color(0xFF7C8A7C);

    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final displayName = user?.userMetadata?['full_name'] as String? ??
        user?.userMetadata?['name'] as String? ??
        user?.email?.split('@').first ??
        (lang == AppLanguage.th ? 'ผู้ใช้งาน LIFT' : 'LIFT User');

    String? memberSince;
    if (user?.createdAt != null) {
      try {
        final dt = DateTime.parse(user!.createdAt);
        final monthsEn = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final monthsTh = ['', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
        final m = lang == AppLanguage.th ? monthsTh[dt.month] : monthsEn[dt.month];
        final year = lang == AppLanguage.th ? dt.year + 543 : dt.year;
        memberSince = lang == AppLanguage.th 
            ? 'สมาชิกตั้งแต่ $m $year' 
            : 'Member since $m $year';
      } catch (_) {}
    }

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
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border, width: 0.5),
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.08),
                      Theme.of(context).cardTheme.color ?? const Color(0xFF151815),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
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
                            color: accent.withValues(alpha: 0.25),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: accent.withValues(alpha: 0.1),
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null ? Icon(Icons.person, color: accent, size: 32) : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFC6FF3D),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFFC6FF3D),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? (lang == AppLanguage.th ? 'ไม่พบอีเมลผู้ใช้งาน' : 'User email not found'),
                            style: TextStyle(fontSize: 13, color: textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (memberSince != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              memberSince,
                              style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Body Metrics Header
              Row(
                children: [
                  Icon(Icons.accessibility, color: textMuted, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    lang == AppLanguage.th ? 'ข้อมูลสรีระร่างกาย' : 'Body Metrics',
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

              // Bio Metrics Grid Panels
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showEditHeightBottomSheet(_profile?.height),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  lang == AppLanguage.th ? 'ส่วนสูง' : 'HEIGHT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: textMuted,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Icon(Icons.edit, size: 12, color: accent),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _profile?.height != null
                                  ? '${_profile!.height!.toStringAsFixed(1)} cm'
                                  : (lang == AppLanguage.th ? 'ไม่ได้ตั้งค่า' : 'Not set'),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showEditWeightBottomSheet(
                        _weightLogs.isNotEmpty ? _weightLogs.first.weightKg : null,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  lang == AppLanguage.th ? 'น้ำหนักตัว' : 'WEIGHT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: textMuted,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Icon(Icons.scale, size: 12, color: accent),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _weightLogs.isNotEmpty
                                  ? '${(isLbs ? _weightLogs.first.weightKg * kgToLbs : _weightLogs.first.weightKg).toStringAsFixed(1)} ${isLbs ? 'lbs' : 'kg'}'
                                  : (lang == AppLanguage.th ? 'ไม่ได้ตั้งค่า' : 'Not set'),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _showWeightHistoryBottomSheet,
                    icon: const Icon(Icons.history, size: 16),
                    label: Text(
                      lang.tr('btn_view_history'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Stats Section
              Row(
                children: [
                  Icon(Icons.bar_chart, color: textMuted, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    lang.tr('nav_stats'),
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
              const StatsSection(),
              const SizedBox(height: 24),

              // Routines Section
              Row(
                children: [
                  Icon(Icons.fitness_center, color: textMuted, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    lang == AppLanguage.th ? 'ตารางฝึกส่วนตัว' : 'Workout Routines',
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
                child: ListTile(
                  leading: Icon(Icons.list_alt_outlined, color: accent),
                  title: Text(
                    lang == AppLanguage.th ? 'ตารางฝึกของฉัน' : 'My Routines',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    lang == AppLanguage.th
                        ? 'สร้าง จัดการ และแชร์ตารางออกกำลังกายล่วงหน้า'
                        : 'Create, manage, and share workout templates',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RoutinesScreen()),
                    );
                  },
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
                          isLbs ? lang.tr('weight_unit_lbs') : lang.tr('weight_unit_kg'),
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: border, width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: isLbs ? () => ref.read(isLbsProvider.notifier).toggle() : null,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: !isLbs ? accent : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'KG',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      color: !isLbs ? Colors.black : textMuted,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: !isLbs ? () => ref.read(isLbsProvider.notifier).toggle() : null,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isLbs ? accent : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'LBS',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      color: isLbs ? Colors.black : textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(indent: 56, endIndent: 16),
                      // Language Row
                      ListTile(
                        leading: Icon(Icons.language_outlined, color: textMuted),
                        title: Text(
                          lang.tr('language_title'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          lang == AppLanguage.th ? lang.tr('language_desc_th') : lang.tr('language_desc_en'),
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: border, width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: lang != AppLanguage.th
                                    ? () => ref.read(languageProvider.notifier).setLanguage(AppLanguage.th)
                                    : null,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: lang == AppLanguage.th ? accent : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'TH',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      color: lang == AppLanguage.th ? Colors.black : textMuted,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: lang != AppLanguage.en
                                    ? () => ref.read(languageProvider.notifier).setLanguage(AppLanguage.en)
                                    : null,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: lang == AppLanguage.en ? accent : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'EN',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      color: lang == AppLanguage.en ? Colors.black : textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(indent: 56, endIndent: 16),
                      // Theme Row
                      ListTile(
                        leading: Icon(
                          themeMode == ThemeMode.dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
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
                          themeMode == ThemeMode.dark ? lang.tr('theme_desc_dark') : lang.tr('theme_desc_light'),
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: border, width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: themeMode != ThemeMode.light
                                    ? () => ref.read(themeProvider.notifier).setThemeMode(ThemeMode.light)
                                    : null,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: themeMode == ThemeMode.light ? accent : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    lang == AppLanguage.th ? 'สว่าง' : 'Light',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      color: themeMode == ThemeMode.light ? Colors.black : textMuted,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: themeMode != ThemeMode.dark
                                    ? () => ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark)
                                    : null,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: themeMode == ThemeMode.dark ? accent : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    lang == AppLanguage.th ? 'มืด' : 'Dark',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      color: themeMode == ThemeMode.dark ? Colors.black : textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                        leading: Icon(Icons.chat_bubble_outline, color: textMuted),
                        title: Text(
                          lang.tr('feedback_title'),
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: Icon(Icons.chevron_right, color: textMuted, size: 18),
                        onTap: _showFeedbackDialog,
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.perm_device_info_outlined, color: textMuted),
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
              const SizedBox(height: 24),

              // Danger Zone Card
              Card(
                color: themeMode == ThemeMode.dark ? const Color(0xFF1E1111) : const Color(0xFFFFF5F5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: themeMode == ThemeMode.dark ? const Color(0xFF3E1F1F) : const Color(0xFFFFD3D3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
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
                        color: themeMode == ThemeMode.dark ? const Color(0xFF3E1F1F) : const Color(0xFFFFD3D3),
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.redAccent),
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

  void _showWeightHistoryBottomSheet() {
    final lang = ref.read(languageProvider);
    final isLbs = ref.read(isLbsProvider);
    final accent = Theme.of(context).colorScheme.primary;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final textMuted = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final startingLog = _weightLogs.isNotEmpty ? _weightLogs.last : null;
            final currentLog = _weightLogs.isNotEmpty ? _weightLogs.first : null;
            
            final startingDisplay = startingLog != null 
                ? (isLbs ? startingLog.weightKg * kgToLbs : startingLog.weightKg) 
                : 0.0;
            final currentDisplay = currentLog != null 
                ? (isLbs ? currentLog.weightKg * kgToLbs : currentLog.weightKg) 
                : 0.0;
            final diffDisplay = currentDisplay - startingDisplay;
            
            final unit = isLbs ? 'lbs' : 'kg';

            final chartLogs = _weightLogs.reversed.toList();
            final spots = <FlSpot>[];
            for (int i = 0; i < chartLogs.length; i++) {
              final log = chartLogs[i];
              final w = isLbs ? log.weightKg * kgToLbs : log.weightKg;
              spots.add(FlSpot(i.toDouble(), w));
            }

            double minWeight = double.infinity;
            double maxWeight = -double.infinity;
            for (final log in chartLogs) {
              final w = isLbs ? log.weightKg * kgToLbs : log.weightKg;
              if (w < minWeight) minWeight = w;
              if (w > maxWeight) maxWeight = w;
            }

            final range = maxWeight - minWeight;
            final padding = range > 0 ? range * 0.15 : 2.0;
            final yMin = spots.isNotEmpty ? minWeight - padding : 0.0;
            final yMax = spots.isNotEmpty ? maxWeight + padding : 100.0;

            int interval = 1;
            if (chartLogs.length > 6) {
              interval = (chartLogs.length / 5).ceil();
            }

            Widget metricCol({required String title, required String value, required Color color}) {
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }

            Widget dividerCol() {
              return Container(
                height: 24,
                width: 0.5,
                color: Theme.of(context).colorScheme.outline,
              );
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lang.tr('weight_history_title'),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  
                  if (_weightLogs.length >= 2) ...[
                    const SizedBox(height: 16),
                    Container(
                      height: 150,
                      padding: const EdgeInsets.only(right: 24, left: 12),
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: (chartLogs.length - 1).toDouble(),
                          minY: yMin,
                          maxY: yMax,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: range > 0 ? (range / 3) : 2.0,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                              strokeWidth: 0.5,
                              dashArray: [5, 5],
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 22,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 || index >= chartLogs.length) return const SizedBox.shrink();
                                  if (index % interval != 0) return const SizedBox.shrink();
                                  final log = chartLogs[index];
                                  final date = DateTime.fromMillisecondsSinceEpoch(log.loggedAt);
                                  final label = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}";
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: textMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                                width: 0.5,
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              preventCurveOverShooting: true,
                              color: accent,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) =>
                                    FlDotCirclePainter(
                                  radius: 4,
                                  color: accent,
                                  strokeWidth: 1,
                                  strokeColor: Theme.of(context).scaffoldBackgroundColor,
                                ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    accent.withValues(alpha: 0.2),
                                    accent.withValues(alpha: 0.0),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (_weightLogs.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          metricCol(
                            title: lang == AppLanguage.th ? 'เริ่มต้น' : 'Starting',
                            value: "${startingDisplay.toStringAsFixed(1)} $unit",
                            color: textPrimary,
                          ),
                          dividerCol(),
                          metricCol(
                            title: lang == AppLanguage.th ? 'ปัจจุบัน' : 'Current',
                            value: "${currentDisplay.toStringAsFixed(1)} $unit",
                            color: textPrimary,
                          ),
                          dividerCol(),
                          metricCol(
                            title: lang == AppLanguage.th ? 'เปลี่ยนแปลง' : 'Net Change',
                            value: "${diffDisplay >= 0 ? '+' : ''}${diffDisplay.toStringAsFixed(1)} $unit",
                            color: diffDisplay < 0 
                                ? const Color(0xFFC6FF3D) 
                                : (diffDisplay > 0 ? Colors.cyan : textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Divider(),
                  Expanded(
                    child: _weightLogs.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                lang.tr('weight_history_empty'),
                                style: const TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            itemCount: _weightLogs.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final log = _weightLogs[index];
                              final weightDisplay = isLbs ? log.weightKg * kgToLbs : log.weightKg;
                              final date = DateTime.fromMillisecondsSinceEpoch(log.loggedAt);
                              final dateFormatted = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.scale_outlined, color: accent, size: 20),
                                title: Text(
                                  "${weightDisplay.toStringAsFixed(1)} ${isLbs ? 'lbs' : 'kg'}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                subtitle: Text(
                                  dateFormatted,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () => _confirmDeleteWeightLog(log.id!, setModalState),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteWeightLog(int logId, void Function(void Function()) setModalState) async {
    final lang = ref.read(languageProvider);
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.tr('btn_delete_confirm')),
        content: Text(lang.tr('btn_delete_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              lang.tr('btn_cancel'),
              style: const TextStyle(color: Color(0xFF7C8A7C)),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              lang.tr('btn_delete'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (proceed == true) {
      try {
        await _weightLogDao.delete(logId);
        final logs = await _weightLogDao.getAll();
        setState(() {
          _weightLogs = logs;
        });
        setModalState(() {});
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }
}
