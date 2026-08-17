import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/translation_provider.dart';
import 'core/providers/cache_provider.dart';
import 'core/providers/tab_provider.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
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
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showChangePasswordDialog();
        });
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

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

  void _showChangePasswordDialog() {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    bool obscureText = true;

    showDialog(
      context: context,
      barrierDismissible: false, // Force user to update password
      builder: (ctx) {
        final lang = ref.watch(languageProvider);
        const accent = Color(0xFFC6FF3D);
        const textPrimary = Color(0xFFF2F5EF);
        const textMuted = Color(0xFF7C8A7C);

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1B1F1B),
              title: Text(
                lang == AppLanguage.th ? 'ตั้งรหัสผ่านใหม่' : 'Reset Password',
                style: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lang == AppLanguage.th
                          ? 'กรุณากรอกรหัสผ่านใหม่ที่คุณต้องการใช้งาน'
                          : 'Please enter your new password to secure your account.',
                      style: const TextStyle(color: textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscureText,
                      style: const TextStyle(color: textPrimary),
                      decoration: InputDecoration(
                        labelText: lang == AppLanguage.th ? 'รหัสผ่านใหม่' : 'New Password',
                        labelStyle: const TextStyle(color: textMuted),
                        prefixIcon: const Icon(Icons.lock_outlined, color: textMuted),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: textMuted,
                          ),
                          onPressed: () {
                            setState(() {
                              obscureText = !obscureText;
                            });
                          },
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF262A24)),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: accent),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return lang == AppLanguage.th ? 'กรุณากรอกรหัสผ่าน' : 'Please enter password';
                        }
                        if (val.length < 6) {
                          return lang == AppLanguage.th
                              ? 'รหัสผ่านต้องยาวอย่างน้อย 6 ตัวอักษร'
                              : 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setState(() {
                            isSaving = true;
                          });
                          try {
                            await Supabase.instance.client.auth.updateUser(
                              UserAttributes(password: passwordController.text),
                            );
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    lang == AppLanguage.th
                                        ? 'เปลี่ยนรหัสผ่านใหม่สำเร็จแล้ว!'
                                        : 'Password updated successfully!',
                                  ),
                                  backgroundColor: const Color(0xFF1B1F1B),
                                ),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    lang == AppLanguage.th
                                        ? 'เกิดข้อผิดพลาด: $e'
                                        : 'Error: $e',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          } finally {
                            setState(() {
                              isSaving = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Text(lang == AppLanguage.th ? 'เปลี่ยนรหัสผ่าน' : 'Update Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
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
              color: themeMode == ThemeMode.dark ? const Color(0xFF262A24) : const Color(0xFFE2E8DF),
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
    const bg = Color(0xFF0A0E0B);
    const surfaceSolid = Color(0xFF121A15);
    const border = Color(0xFF223326);
    const accent = Color(0xFF10B981);
    const onAccent = Color(0xFF000000);
    const textPrimary = Color(0xFFFFFFFF);
    const textMuted = Color(0xFF94A3B8);
    const textSecondary = Color(0xFFE2E8F0);

    const brightness = Brightness.dark;

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
        fillColor: const Color(0xFF16221B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 0.5,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: accent.withValues(alpha: 0.1),
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
        backgroundColor: surfaceSolid,
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
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceSolid,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      ),
    );
  }
}
