import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/providers/theme_provider.dart';
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
    final themeMode = ref.watch(themeProvider);
    final lang = ref.watch(languageProvider);
    final cacheInit = user != null ? ref.watch(cacheInitProvider) : null;
    final currentIndex = ref.watch(activeTabProvider);

    final mainScaffold = Scaffold(
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: themeMode == ThemeMode.dark
                  ? AppColors.border
                  : const Color(0xFFE2E8DF),
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: _onTabChanged,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: lang.tr('nav_home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.tune_outlined),
              selectedIcon: const Icon(Icons.tune),
              label: lang == AppLanguage.th ? 'ตาราง' : 'Routines',
            ),
            NavigationDestination(
              icon: const Icon(Icons.trending_up_outlined),
              selectedIcon: const Icon(Icons.trending_up),
              label: lang.tr('nav_stats'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.smart_toy_outlined),
              selectedIcon: const Icon(Icons.smart_toy),
              label: lang.tr('nav_ai'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: lang == AppLanguage.th ? 'ฉัน' : 'Profile',
            ),
          ],
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
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            lang == AppLanguage.th
                                ? 'กำลังโหลดข้อมูลจากคลาวด์...'
                                : 'Loading data from cloud...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.7),
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
          surface: surfaceSolid,
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
          side: const BorderSide(color: border, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        isDense: true,
        labelStyle: TextStyle(color: textMuted),
        hintStyle: TextStyle(color: textMuted),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 0.5, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: accent.withValues(alpha: 0.15),
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: accent, size: 24);
          }
          return IconThemeData(color: textMuted, size: 24);
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
