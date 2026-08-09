import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/unit_provider.dart';
import '../auth/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final isLbs = ref.watch(isLbsProvider);

    const bg = Color(0xFF0A0C0A);
    const border = Color(0xFF262A24);
    const accent = Color(0xFFC6FF3D);
    const textPrimary = Color(0xFFF2F5EF);
    const textMuted = Color(0xFF7C8A7C);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'โปรไฟล์',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: accent, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: accent,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'อีเมลผู้ใช้งาน',
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? 'ไม่พบข้อมูลผู้ใช้งาน',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
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

              // Settings Header
              Text(
                'ตั้งค่าระบบ',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Unit Preference Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.scale_outlined, color: textMuted),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'หน่วยน้ำหนัก',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                'กำลังใช้: ${isLbs ? "ปอนด์ (lbs)" : "กิโลกรัม (kg)"}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // kg/lbs toggle button
                      Row(
                        children: [
                          GestureDetector(
                            onTap: isLbs ? () => ref.read(isLbsProvider.notifier).toggle() : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: !isLbs ? accent : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: !isLbs ? null : Border.all(color: border),
                              ),
                              child: Text(
                                'KG',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: !isLbs ? bg : textMuted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: !isLbs ? () => ref.read(isLbsProvider.notifier).toggle() : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isLbs ? accent : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: isLbs ? null : Border.all(color: border),
                              ),
                              child: Text(
                                'LBS',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: isLbs ? bg : textMuted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Sign Out Button
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).signOut();
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('ออกจากระบบ'),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Color(0xFF3A1F1F)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
