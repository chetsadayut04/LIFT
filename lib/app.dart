import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/history/history_provider.dart';
import 'features/history/history_screen.dart';
import 'features/home/home_provider.dart';
import 'features/home/home_screen.dart';
import 'features/stats/stats_provider.dart';
import 'features/stats/stats_screen.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  int _currentIndex = 0;

  void _onTabChanged(int i) {
    setState(() => _currentIndex = i);
    // Reload data when switching to history or stats tab
    if (i == 0) ref.read(homeProvider.notifier).load();
    if (i == 1) ref.read(historyProvider.notifier).load();
    if (i == 2) ref.read(statsProvider.notifier).load();
  }

  static const _screens = [
    HomeScreen(),
    HistoryScreen(),
    StatsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    return MaterialApp(
      title: 'LIFT',
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      home: user == null
          ? const LoginScreen()
          : Scaffold(
              body: IndexedStack(index: _currentIndex, children: _screens),
              bottomNavigationBar: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFF262A24), width: 0.5),
                  ),
                ),
                child: NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onTabChanged,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'หน้าหลัก',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.history_outlined),
                      selectedIcon: Icon(Icons.history),
                      label: 'ประวัติ',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.bar_chart_outlined),
                      selectedIcon: Icon(Icons.bar_chart),
                      label: 'สถิติ',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: 'โปรไฟล์',
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  ThemeData _theme() {
    const bg = Color(0xFF0A0C0A);
    const surfaceSolid = Color(0xFF1B1F1B);
    const border = Color(0xFF262A24);
    const accent = Color(0xFFC6FF3D);
    const textPrimary = Color(0xFFF2F5EF);
    const textMuted = Color(0xFF7C8A7C);

    final cs = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: accent,
      onPrimary: bg,
      surface: surfaceSolid,
      outline: border,
      onSurface: textPrimary,
    );

    final baseTextTheme = GoogleFonts.spaceGroteskTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ).apply(bodyColor: textPrimary, displayColor: textPrimary);

    final textTheme = baseTextTheme.copyWith(
      bodyLarge: GoogleFonts.inter(textStyle: baseTextTheme.bodyLarge, color: textPrimary),
      bodyMedium: GoogleFonts.inter(textStyle: baseTextTheme.bodyMedium, color: textPrimary),
      bodySmall: GoogleFonts.inter(textStyle: baseTextTheme.bodySmall, color: textMuted),
      labelLarge: GoogleFonts.inter(textStyle: baseTextTheme.labelLarge, color: textPrimary),
      labelMedium: GoogleFonts.inter(textStyle: baseTextTheme.labelMedium, color: textMuted),
      labelSmall: GoogleFonts.inter(textStyle: baseTextTheme.labelSmall, color: textMuted),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
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
        iconTheme: const IconThemeData(color: textMuted),
        actionsIconTheme: const IconThemeData(color: textMuted),
      ),
      cardTheme: CardThemeData(
        color: surfaceSolid,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF15181A),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        isDense: true,
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: const TextStyle(color: textMuted),
      ),
      dividerTheme: const DividerThemeData(
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
            return const IconThemeData(color: accent, size: 24);
          }
          return const IconThemeData(color: textMuted, size: 24);
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: bg,
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
          side: const BorderSide(color: border),
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
          side: const BorderSide(color: border),
        ),
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(color: textMuted),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceSolid,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
