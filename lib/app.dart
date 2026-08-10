import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/translation_provider.dart';
import 'core/providers/cache_provider.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/history/history_provider.dart';
import 'features/history/history_screen.dart';
import 'features/home/home_provider.dart';
import 'features/home/home_screen.dart';
import 'features/stats/stats_provider.dart';
import 'features/ai_coach/ai_chat_screen.dart';
import 'features/ai_coach/ai_chat_provider.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  int _currentIndex = 0;

  void _onTabChanged(int i) {
    setState(() => _currentIndex = i);
    // Reload data when switching tabs
    if (i == 0) ref.read(homeProvider.notifier).load();
    if (i == 1) ref.read(historyProvider.notifier).load();
    if (i == 2) ref.read(aiChatProvider.notifier).refreshContext();
    if (i == 3) ref.read(statsProvider.notifier).load();
  }

  static const _screens = [
    HomeScreen(),
    HistoryScreen(),
    AiChatScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);
    final lang = ref.watch(languageProvider);
    final cacheInit = user != null ? ref.watch(cacheInitProvider) : null;

    final mainScaffold = Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: themeMode == ThemeMode.dark ? const Color(0xFF262A24) : const Color(0xFFE2E8DF),
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabChanged,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: lang.tr('nav_home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.history_outlined),
              selectedIcon: const Icon(Icons.history),
              label: lang.tr('nav_history'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.smart_toy_outlined),
              selectedIcon: const Icon(Icons.smart_toy),
              label: lang.tr('nav_ai'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: lang.tr('nav_profile'),
            ),
          ],
        ),
      ),
    );

    return MaterialApp(
      title: 'LIFT',
      debugShowCheckedModeBanner: false,
      theme: _theme(themeMode),
      home: user == null
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
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
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
                      const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
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
                        child: Text(lang == AppLanguage.th ? 'ลองใหม่' : 'Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ) ?? const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }

  ThemeData _theme(ThemeMode mode) {
    final isDark = mode == ThemeMode.dark;

    final bg = isDark ? const Color(0xFF0A0C0A) : const Color(0xFFF4F6F3);
    final surfaceSolid = isDark ? const Color(0xFF151815) : const Color(0xFFFFFFFF);
    final border = isDark ? const Color(0xFF222822) : const Color(0xFFDCE2DC);
    final accent = isDark ? const Color(0xFFC6FF3D) : const Color(0xFF4D8300);
    final onAccent = isDark ? const Color(0xFF0A0C0A) : const Color(0xFFFFFFFF);
    final textPrimary = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF101410);
    final textMuted = isDark ? const Color(0xFF9FB09F) : const Color(0xFF4E594E);
    final textSecondary = isDark ? const Color(0xFFD2DDD2) : const Color(0xFF323B32);

    final brightness = isDark ? Brightness.dark : Brightness.light;

    final cs = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
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
      bodyLarge: GoogleFonts.inter(textStyle: baseTextTheme.bodyLarge, color: textPrimary),
      bodyMedium: GoogleFonts.inter(textStyle: baseTextTheme.bodyMedium, color: textSecondary),
      bodySmall: GoogleFonts.inter(textStyle: baseTextTheme.bodySmall, color: textMuted),
      labelLarge: GoogleFonts.inter(textStyle: baseTextTheme.labelLarge, color: textPrimary),
      labelMedium: GoogleFonts.inter(textStyle: baseTextTheme.labelMedium, color: textSecondary),
      labelSmall: GoogleFonts.inter(textStyle: baseTextTheme.labelSmall, color: textMuted),
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
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: textMuted),
        actionsIconTheme: IconThemeData(color: textMuted),
      ),
      cardTheme: CardThemeData(
        color: surfaceSolid,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF15181A) : const Color(0xFFEDF1EC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        isDense: true,
        labelStyle: TextStyle(color: textMuted),
        hintStyle: TextStyle(color: textMuted),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 0.5,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: accent.withValues(alpha: 0.16),
        height: 60,
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
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceSolid,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(color: textMuted),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceSolid,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
