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
import '../../core/providers/translation_provider.dart';
import '../../core/providers/unit_provider.dart';
import '../auth/auth_provider.dart';
import '../stats/stats_provider.dart';

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
  final _feedbackController = TextEditingController();
  bool _feedbackSent = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

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

  Future<void> _sendFeedbackFromProfile() async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) return;
    setState(() => _feedbackSent = true);
    await _sendFeedback(text);
    _feedbackController.clear();
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      setState(() => _feedbackSent = false);
    }
  }

  Widget _buildStatItem(String thLabel, String value, AppLanguage lang) {
    String label = thLabel;
    if (lang == AppLanguage.en) {
      if (thLabel == 'เซสชัน') label = 'Sessions';
      if (thLabel == 'สัปดาห์นี้') label = 'This Week';
      if (thLabel == 'วันต่อเนื่อง') label = 'Streak';
    }
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.sarabun(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorButton({
    required bool isSelected,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.sarabun(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF000000) : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmDialog() {
    final lang = ref.read(languageProvider);
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1B1F1B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('👋', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 16),
                Text(
                  lang == AppLanguage.th ? 'ออกจากระบบ?' : 'Log out?',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF2F5EF),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lang == AppLanguage.th
                      ? 'คุณต้องการออกจากระบบใช่หรือไม่'
                      : 'Are you sure you want to log out?',
                  style: GoogleFonts.sarabun(
                    fontSize: 14,
                    color: const Color(0xFF7C8A7C),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    // Cancel
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E211F),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            lang == AppLanguage.th ? 'ยกเลิก' : 'Cancel',
                            style: GoogleFonts.sarabun(
                              fontSize: 14,
                              color: const Color(0xFF8E9A8E),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Confirm logout
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await ref.read(authProvider.notifier).signOut();
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
                            side: BorderSide(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            lang == AppLanguage.th ? 'ออกจากระบบ' : 'Log out',
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFF87171),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final isLbs = ref.watch(isLbsProvider);
    final lang = ref.watch(languageProvider);

    final bg = Theme.of(context).scaffoldBackgroundColor;
    final accent = Theme.of(context).colorScheme.primary;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFFF2F5EF);
    final textMuted = Theme.of(context).textTheme.bodySmall?.color ?? const Color(0xFF7C8A7C);

    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final displayName = user?.userMetadata?['full_name'] as String? ??
        user?.userMetadata?['name'] as String? ??
        user?.email?.split('@').first ??
        (lang == AppLanguage.th ? 'ผู้ใช้งาน LIFT' : 'LIFT User');

    String? memberSinceLabel;
    final userCreatedAt = user?.createdAt;
    if (userCreatedAt != null) {
      try {
        final dt = DateTime.parse(userCreatedAt);
        final monthsEn = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final monthsTh = ['', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
        final m = lang == AppLanguage.th ? monthsTh[dt.month] : monthsEn[dt.month];
        final year = lang == AppLanguage.th ? dt.year + 543 : dt.year;
        memberSinceLabel = '$m $year';
      } catch (_) {}
    }

    // Calculate stats
    final stats = ref.watch(statsProvider);
    final totalSessions = stats.workoutDates.length;

    // Sessions this week
    int sessionsThisWeek = 0;
    final now = DateTime.now();
    final thisMonday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final thisSunday = thisMonday.add(const Duration(days: 6));
    for (final dStr in stats.workoutDates) {
      final date = DateTime.tryParse(dStr);
      if (date != null && !date.isBefore(thisMonday) && !date.isAfter(thisSunday)) {
        sessionsThisWeek++;
      }
    }

    // Streak
    int streak = 0;
    final sortedDates = stats.workoutDates
        .map((d) => DateTime.tryParse(d))
        .where((d) => d != null)
        .map((d) => DateTime(d!.year, d.month, d.day))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (sortedDates.isNotEmpty) {
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      if (sortedDates.first == today || sortedDates.first == yesterday) {
        streak = 1;
        var current = sortedDates.first;
        for (int i = 1; i < sortedDates.length; i++) {
          final prev = sortedDates[i];
          final diff = current.difference(prev).inDays;
          if (diff == 1) {
            streak++;
            current = prev;
          } else if (diff > 1) {
            break;
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header / Profile ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                child: Column(
                  children: [
                    // Avatar with Gradient border matching Figma
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          width: 3,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: avatarUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: Image.network(
                                avatarUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                              style: GoogleFonts.barlowCondensed(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0A0C0A),
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      displayName,
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? 'somchai@email.com',
                      style: GoogleFonts.sarabun(
                        fontSize: 13,
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Google connect status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E211F),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                            width: 14,
                            height: 14,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.g_mobiledata,
                              size: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            lang == AppLanguage.th ? 'เชื่อมต่อผ่าน Google' : 'Connected with Google',
                            style: GoogleFonts.sarabun(
                              fontSize: 11,
                              color: const Color(0xFF777777),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats Row Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1F1B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildStatItem('เซสชัน', '$totalSessions', lang),
                          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.04)),
                          _buildStatItem('สัปดาห์นี้', '$sessionsThisWeek', lang),
                          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.04)),
                          _buildStatItem('วันต่อเนื่อง', '$streak', lang),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Language ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang == AppLanguage.th ? 'ภาษา' : 'LANGUAGE',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5A6A5A),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1F1B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSelectorButton(
                              isSelected: lang == AppLanguage.th,
                              label: '🇹🇭 ภาษาไทย',
                              onTap: () => ref.read(languageProvider.notifier).setLanguage(AppLanguage.th),
                            ),
                          ),
                          Expanded(
                            child: _buildSelectorButton(
                              isSelected: lang == AppLanguage.en,
                              label: '🇬🇧 English',
                              onTap: () => ref.read(languageProvider.notifier).setLanguage(AppLanguage.en),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Weight unit ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang == AppLanguage.th ? 'หน่วยน้ำหนัก' : 'WEIGHT UNIT',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5A6A5A),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1F1B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSelectorButton(
                              isSelected: !isLbs,
                              label: lang == AppLanguage.th ? 'กิโลกรัม (kg)' : 'Kilograms (kg)',
                              onTap: isLbs ? () => ref.read(isLbsProvider.notifier).toggle() : () {},
                            ),
                          ),
                          Expanded(
                            child: _buildSelectorButton(
                              isSelected: isLbs,
                              label: lang == AppLanguage.th ? 'ปอนด์ (lbs)' : 'Pounds (lbs)',
                              onTap: !isLbs ? () => ref.read(isLbsProvider.notifier).toggle() : () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),


              // ── Extra: Body Metrics grid ───────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showEditHeightBottomSheet(_profile?.height),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B1F1B),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  width: 1,
                                ),
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
                                color: const Color(0xFF1B1F1B),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  width: 1,
                                ),
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
                  ],
                ),
              ),
              const SizedBox(height: 10),



              // ── Extra: Stats Section (Calendar & charts) ───────────


              // ── Feedback ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang == AppLanguage.th ? 'ส่งความคิดเห็น' : 'FEEDBACK',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5A6A5A),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1F1B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        children: [
                          TextField(
                            controller: _feedbackController,
                            maxLines: 4,
                            style: GoogleFonts.sarabun(
                              fontSize: 14,
                              color: const Color(0xFFE0E0E0),
                              height: 1.6,
                            ),
                            decoration: InputDecoration(
                              hintText: lang == AppLanguage.th
                                  ? 'แจ้งปัญหา หรือแนะนำฟีเจอร์ใหม่...'
                                  : 'Report bugs or suggest features...',
                              hintStyle: const TextStyle(color: Color(0xFF555555)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: InputBorder.none,
                            ),
                            onChanged: (text) => setState(() {}),
                          ),
                          if (_feedbackSent) ...[
                            Container(
                              margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.2),
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                lang == AppLanguage.th
                                    ? '✓ ขอบคุณสำหรับความคิดเห็นครับ!'
                                    : '✓ Thank you for your feedback!',
                                style: GoogleFonts.sarabun(
                                  fontSize: 13,
                                  color: accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ] else ...[
                            GestureDetector(
                              onTap: _feedbackController.text.trim().isEmpty ? null : _sendFeedbackFromProfile,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                decoration: BoxDecoration(
                                  color: _feedbackController.text.trim().isNotEmpty
                                      ? accent.withValues(alpha: 0.12)
                                      : const Color(0xFF1E211F),
                                  border: Border.all(
                                    color: _feedbackController.text.trim().isNotEmpty
                                        ? accent.withValues(alpha: 0.3)
                                        : Colors.white.withValues(alpha: 0.06),
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  lang == AppLanguage.th ? 'ส่งความคิดเห็น' : 'Send Feedback',
                                  style: GoogleFonts.sarabun(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _feedbackController.text.trim().isNotEmpty
                                        ? accent
                                        : const Color(0xFF444444),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── App info ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1F1B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            lang == AppLanguage.th ? 'เวอร์ชัน' : 'Version',
                            style: GoogleFonts.sarabun(
                              fontSize: 13,
                              color: const Color(0xFF7C8A7C),
                            ),
                          ),
                          Text(
                            '1.0.0-beta',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13,
                              color: const Color(0xFF5A6A5A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            lang == AppLanguage.th ? 'สมาชิกตั้งแต่' : 'Member since',
                            style: GoogleFonts.sarabun(
                              fontSize: 13,
                              color: const Color(0xFF7C8A7C),
                            ),
                          ),
                          Text(
                            memberSinceLabel ?? 'ม.ค. 2025',
                            style: GoogleFonts.sarabun(
                              fontSize: 13,
                              color: const Color(0xFF5A6A5A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Logout Button ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _showLogoutConfirmDialog,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.08),
                      side: BorderSide(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      lang == AppLanguage.th ? 'ออกจากระบบ' : 'Log out',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF87171),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Danger Zone (Delete Account Link) ──────────────────
              Center(
                child: TextButton(
                  onPressed: _showDeleteAccountDialog,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF5A3C),
                  ),
                  child: Text(
                    lang == AppLanguage.th ? 'ลบบัญชีผู้ใช้งานถาวร' : 'Delete Account Permanently',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 32),
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
                                ? accent 
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
