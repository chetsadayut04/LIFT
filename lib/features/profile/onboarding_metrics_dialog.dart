import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/profile_dao.dart';
import '../../core/database/weight_log_dao.dart';
import '../../core/models/profile.dart';
import '../../core/providers/translation_provider.dart';
import '../../core/providers/unit_provider.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_provider.dart';
import '../home/home_provider.dart';

class OnboardingMetricsDialog extends ConsumerStatefulWidget {
  const OnboardingMetricsDialog({super.key});

  /// Checks if the current user is a newly registered user without height & weight,
  /// and shows the onboarding dialog if they haven't seen it yet.
  static Future<void> checkAndShow(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authProvider);
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final seenKey = 'onboarding_metrics_seen_${user.id}';
    if (prefs.getBool(seenKey) == true) return;

    // Check if user already has height or weight records
    try {
      final profileDao = ProfileDao();
      final profile = await profileDao.getProfile(user.id);
      if (profile?.height != null) {
        await prefs.setBool(seenKey, true);
        return;
      }

      final weightLogDao = WeightLogDao();
      final weightLogs = await weightLogDao.getAll();
      if (weightLogs.isNotEmpty) {
        await prefs.setBool(seenKey, true);
        return;
      }
    } catch (_) {
      // If error querying local cache, do not block user
      return;
    }

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => const OnboardingMetricsDialog(),
    );
  }

  @override
  ConsumerState<OnboardingMetricsDialog> createState() =>
      _OnboardingMetricsDialogState();
}

class _OnboardingMetricsDialogState
    extends ConsumerState<OnboardingMetricsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _handleSkip() async {
    final user = ref.read(authProvider);
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_metrics_seen_${user.id}', true);
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final user = ref.read(authProvider);
    final lang = ref.read(languageProvider);
    final isLbs = ref.read(isLbsProvider);

    if (user == null) {
      Navigator.of(context).pop();
      return;
    }

    try {
      final heightText = _heightController.text.trim().replaceAll(',', '.');
      final weightText = _weightController.text.trim().replaceAll(',', '.');

      final heightCm = double.tryParse(heightText);
      final rawWeight = double.tryParse(weightText);

      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. Save height to Profile
      if (heightCm != null && heightCm > 0) {
        final profileDao = ProfileDao();
        await profileDao.saveProfile(
          Profile(
            id: user.id,
            height: heightCm,
            updatedAt: now,
          ),
        );
      }

      // 2. Save weight to WeightLog
      if (rawWeight != null && rawWeight > 0) {
        final weightKg = inputToKg(rawWeight, isLbs);
        final weightLogDao = WeightLogDao();
        await weightLogDao.insert(weightKg, now);
      }

      // 3. Mark onboarding as completed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_metrics_seen_${user.id}', true);

      // 4. Refresh home & stats
      ref.read(homeProvider.notifier).load();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang == AppLanguage.th
                  ? 'บันทึกข้อมูลสรีระร่างกายเรียบร้อยแล้ว!'
                  : 'Body metrics saved successfully!',
              style: GoogleFonts.sarabun(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang == AppLanguage.th
                  ? 'เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e'
                  : 'Failed to save metrics: $e',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isLbs = ref.watch(isLbsProvider);
    final weightUnit = isLbs ? 'lbs' : 'kg';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Icon Badge
                Center(
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      color: AppColors.onPrimary,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                Text(
                  lang == AppLanguage.th
                      ? 'ยินดีต้อนรับสู่ LIFT!'
                      : 'Welcome to LIFT!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),

                // Description
                Text(
                  lang == AppLanguage.th
                      ? 'กรอกข้อมูลสรีระร่างกายของคุณ เพื่อให้ระบบช่วยวางแผนและติดตามพัฒนาการได้อย่างแม่นยำ'
                      : 'Set your initial body metrics so LIFT can accurately track your fitness progress.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sarabun(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Height Input Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.height_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          lang == AppLanguage.th
                              ? 'ส่วนสูง (cm)'
                              : 'Height (cm)',
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        hintText: lang == AppLanguage.th ? 'เช่น 175.0' : 'e.g. 175.0',
                        hintStyle: GoogleFonts.sarabun(
                          color: AppColors.textMuted.withValues(alpha: 0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                        suffixText: 'cm',
                        suffixStyle: GoogleFonts.jetBrainsMono(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 1,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (val) {
                        final text = val?.trim().replaceAll(',', '.') ?? '';
                        if (text.isEmpty) {
                          return lang == AppLanguage.th
                              ? 'กรุณากรอกส่วนสูง'
                              : 'Please enter height';
                        }
                        final numVal = double.tryParse(text);
                        if (numVal == null || numVal < 50 || numVal > 260) {
                          return lang == AppLanguage.th
                              ? 'ส่วนสูงต้องอยู่ระหว่าง 50 - 260 cm'
                              : 'Height must be between 50 - 260 cm';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Weight Input Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.scale_rounded,
                          size: 15,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          lang == AppLanguage.th
                              ? 'น้ำหนักตัว ($weightUnit)'
                              : 'Weight ($weightUnit)',
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        hintText: isLbs
                            ? (lang == AppLanguage.th ? 'เช่น 155.0' : 'e.g. 155.0')
                            : (lang == AppLanguage.th ? 'เช่น 70.0' : 'e.g. 70.0'),
                        hintStyle: GoogleFonts.sarabun(
                          color: AppColors.textMuted.withValues(alpha: 0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                        suffixText: weightUnit,
                        suffixStyle: GoogleFonts.jetBrainsMono(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.secondary,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 1,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (val) {
                        final text = val?.trim().replaceAll(',', '.') ?? '';
                        if (text.isEmpty) {
                          return lang == AppLanguage.th
                              ? 'กรุณากรอกน้ำหนักตัว'
                              : 'Please enter weight';
                        }
                        final numVal = double.tryParse(text);
                        final minW = isLbs ? 45.0 : 20.0;
                        final maxW = isLbs ? 700.0 : 350.0;
                        if (numVal == null || numVal < minW || numVal > maxW) {
                          return lang == AppLanguage.th
                              ? 'น้ำหนักต้องอยู่ระหว่าง ${minW.toInt()} - ${maxW.toInt()} $weightUnit'
                              : 'Weight must be between ${minW.toInt()} - ${maxW.toInt()} $weightUnit';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 26),

                // Primary Save Button
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : Text(
                            lang == AppLanguage.th
                                ? 'บันทึกและเริ่มต้นใช้งาน'
                                : 'Save & Get Started',
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),

                // Secondary "Skip / Set up later" Button
                TextButton(
                  onPressed: _isSaving ? null : _handleSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    lang == AppLanguage.th
                        ? 'ไว้ตั้งค่าทีหลัง'
                        : 'Set up later',
                    style: GoogleFonts.sarabun(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

