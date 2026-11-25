import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/providers/translation_provider.dart';
import 'core/providers/cache_provider.dart';
import 'core/providers/tab_provider.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/home/home_provider.dart';
import 'features/home/home_screen.dart';
import 'features/workout/routine_provider.dart';
import 'features/workout/routines_screen.dart';
import 'features/stats/stats_screen.dart';
import 'features/stats/stats_provider.dart';
import 'features/ai_coach/ai_chat_screen.dart';
import 'features/ai_coach/ai_chat_provider.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  void _onTabChanged(int i) {
    ref.read(activeTabProvider.notifier).state = i;
    // Reload data when switching tabs
    if (i == 0) ref.read(homeProvider.notifier).load();
    if (i == 1) ref.read(routineProvider.notifier).load();
    if (i == 2) ref.read(statsProvider.notifier).load();
    if (i == 3) ref.read(aiChatProvider.notifier).refreshContext();
  }

  static const _screens = [
    HomeScreen(),
    RoutinesScreen(),
    StatsScreen(),
    AiChatScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final isRecovery = ref.watch(passwordRecoveryProvider);
    final lang = ref.watch(languageProvider);
    final cacheInit = user != null ? ref.watch(cacheInitProvider) : null;
    final currentIndex = ref.watch(activeTabProvider);

    final mainScaffold = Scaffold(
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1.0),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                _TelemetryNavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: lang.tr('nav_home'),
                  selected: currentIndex == 0,
                  onTap: () => _onTabChanged(0),
                ),
                _TelemetryNavItem(
                  icon: Icons.tune_outlined,
                  selectedIcon: Icons.tune_rounded,
                  label: lang == AppLanguage.th ? 'ตาราง' : 'Routines',
                  selected: currentIndex == 1,
                  onTap: () => _onTabChanged(1),
                ),
                _TelemetryNavItem(
                  icon: Icons.trending_up_outlined,
                  selectedIcon: Icons.trending_up_rounded,
                  label: lang.tr('nav_stats'),
                  selected: currentIndex == 2,
                  onTap: () => _onTabChanged(2),
                ),
                _TelemetryNavItem(
                  icon: Icons.bolt_outlined,
                  selectedIcon: Icons.bolt_rounded,
                  label: lang.tr('nav_ai'),
                  selected: currentIndex == 3,
                  onTap: () => _onTabChanged(3),
                ),
                _TelemetryNavItem(
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person_rounded,
                  label: lang == AppLanguage.th ? 'ฉัน' : 'Profile',
                  selected: currentIndex == 4,
                  onTap: () => _onTabChanged(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return MaterialApp(
      title: 'LIFT',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: _theme(ThemeMode.dark),
      darkTheme: _theme(ThemeMode.dark),
      home: isRecovery
          ? const ResetPasswordScreen()
          : user == null
          ? const LoginScreen()
          : cacheInit?.when(
                  data: (_) => mainScaffold,
                  loading: () => Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            lang == AppLanguage.th
                                ? 'กำลังโหลดข้อมูลจากคลาวด์...'
                                : 'Loading data from cloud...',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  error: (err, stack) => Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 40,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            lang == AppLanguage.th
                                ? 'เกิดข้อผิดพลาดในการโหลดข้อมูล'
                                : 'Error loading data from cloud',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => ref.refresh(cacheInitProvider),
                            child: Text(
                              lang == AppLanguage.th ? 'ลองใหม่' : 'Retry',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ) ??
                const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
    );
  }

  ThemeData _theme(ThemeMode mode) {
    const bg = AppColors.bg;
    const surfaceSolid = AppColors.surface;
    const border = AppColors.border;
    const accent = AppColors.primary;
    const onAccent = AppColors.onPrimary;
    const textPrimary = AppColors.textPrimary;
    const textMuted = AppColors.textMuted;
    const textSecondary = AppColors.textSecondary;

    const brightness = Brightness.dark;

    final cs = ColorScheme.fromSeed(seedColor: accent, brightness: brightness)
        .copyWith(
          primary: accent,
          onPrimary: onAccent,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          tertiary: AppColors.tertiary,
          onTertiary: AppColors.onTertiary,
          surface: surfaceSolid,
          surfaceContainerHighest: AppColors.surfaceElevated,
          outline: border,
          onSurface: textPrimary,
        );

    final baseTextTheme = GoogleFonts.spaceGroteskTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).apply(bodyColor: textPrimary, displayColor: textPrimary);

    final textTheme = baseTextTheme.copyWith(
      bodyLarge: GoogleFonts.inter(
        textStyle: baseTextTheme.bodyLarge,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        textStyle: baseTextTheme.bodyMedium,
        color: textSecondary,
      ),
      bodySmall: GoogleFonts.inter(
        textStyle: baseTextTheme.bodySmall,
        color: textMuted,
      ),
      labelLarge: GoogleFonts.inter(
        textStyle: baseTextTheme.labelLarge,
        color: textPrimary,
      ),
      labelMedium: GoogleFonts.inter(
        textStyle: baseTextTheme.labelMedium,
        color: textSecondary,
      ),
      labelSmall: GoogleFonts.inter(
        textStyle: baseTextTheme.labelSmall,
        color: textMuted,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      textTheme: textTheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: textMuted),
        actionsIconTheme: const IconThemeData(color: textMuted),
      ),
      cardTheme: CardThemeData(
        color: surfaceSolid,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        isDense: true,
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: const TextStyle(color: textMuted),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1.0, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: accent.withValues(alpha: 0.18),
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.barlowCondensed(
              color: accent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            );
          }
          return GoogleFonts.barlowCondensed(
            color: textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: accent, size: 24);
          }
          return const IconThemeData(color: textMuted, size: 22);
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: border, width: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border, width: 0.5),
        ),
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(color: textMuted),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _TelemetryNavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TelemetryNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: selected ? 24 : 0,
              height: 2,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            Icon(selected ? selectedIcon : icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.barlowCondensed(
                color: color,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
