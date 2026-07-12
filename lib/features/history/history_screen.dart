import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home/home_provider.dart';
import '../stats/stats_provider.dart';
import 'history_provider.dart';
import 'session_detail_screen.dart';

const _kAccent = Color(0xFFC6FF3D);
const _kTextPrimary = Color(0xFFF2F5EF);
const _kTextSec = Color(0xFFB8C2B4);
const _kTextMuted = Color(0xFF7C8A7C);

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ประวัติ')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('เกิดข้อผิดพลาด: $e', style: const TextStyle(color: _kTextSec)),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(
              child: Text('ยังไม่มีประวัติ', style: TextStyle(color: _kTextMuted)),
            );
          }
          // Build grouped list: interleave month headers
          final items = <Object>[];
          String? lastMonth;
          for (final s in sessions) {
            final month = s.session.date.substring(0, 7);
            if (month != lastMonth) {
              items.add(month);
              lastMonth = month;
            }
            items.add(s);
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              if (item is String) {
                // Month header
                final parts = item.split('-');
                final y = int.tryParse(parts[0]) ?? 0;
                final m = int.tryParse(parts[1]) ?? 1;
                const thaiMonths = ['', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                  child: Text(
                    '${thaiMonths[m]} ${y + 543}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kTextMuted, letterSpacing: 0.5),
                  ),
                );
              }
              final s = item as SessionSummary;
              return Column(
                children: [
                  _SessionTile(
                    summary: s,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SessionDetailScreen(sessionId: s.session.id!)),
                    ).then((_) => ref.read(historyProvider.notifier).load()),
                    onDelete: () => _confirmDelete(
                      context,
                      s.session.date,
                      () async {
                        await ref.read(historyProvider.notifier).deleteSession(s.session.id!);
                        ref.read(homeProvider.notifier).load();
                        ref.read(statsProvider.notifier).load();
                      },
                    ),
                  ),
                  const Divider(height: 1),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, String date, VoidCallback onConfirm) {
    final parts = date.split('-');
    final dateStr = parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : date;
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบ session?'),
        content: Text('ลบ workout วันที่ $dateStr?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1A0800),
              foregroundColor: const Color(0xFFFF5A3C),
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final SessionSummary summary;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionTile({required this.summary, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final s = summary.session;
    final parts = s.date.split('-');
    final day = parts.length == 3 ? parts[2] : '?';
    final month = parts.length == 3 ? _monthStr(int.tryParse(parts[1]) ?? 1) : s.date;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Date block
            SizedBox(
              width: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      letterSpacing: -0.5,
                      color: _kTextPrimary,
                    ),
                  ),
                  Text(
                    month,
                    style: const TextStyle(fontSize: 11, color: _kTextSec, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (s.name != null)
                    Text(
                      s.name!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        color: _kTextPrimary,
                      ),
                    ),
                  Text(
                    '${summary.exerciseCount} ท่า · ${summary.setCount} sets',
                    style: const TextStyle(fontSize: 13, color: _kTextSec, height: 1.3),
                  ),
                ],
              ),
            ),
            // Finished / active indicator
            if (!s.isFinished)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9F1C).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('กำลังเล่น',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFFF9F1C))),
              )
            else
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(right: 12),
                decoration: const BoxDecoration(color: _kAccent, shape: BoxShape.circle),
              ),
            GestureDetector(
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Icon(Icons.delete_outline, size: 17, color: _kTextMuted),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: _kTextMuted),
          ],
        ),
      ),
    );
  }

  String _monthStr(int m) {
    const months = [
      '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
    ];
    return m >= 1 && m <= 12 ? months[m] : '';
  }
}
