import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/providers/translation_provider.dart';
import 'active_workout_provider.dart';
import 'active_workout_screen.dart';
import 'add_exercise_dialog.dart';
import 'routine_provider.dart';
import '../../core/utils/routine_image_helper.dart';

class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(routineProvider);
    final lang = ref.watch(languageProvider);
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? const Color(0xFFF2F5EF);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Custom Header matching Figma 1:1
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang == AppLanguage.th ? 'ตารางของฉัน' : 'My Routines',
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Row(
                    children: [
                      // Camera Scanner / Import QR button
                      GestureDetector(
                        onTap: () => _importRoutineFromQr(context, ref),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E211F),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.qr_code_scanner_outlined,
                            size: 18,
                            color: Color(0xFF8E9A8E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Create new routine button
                      GestureDetector(
                        onTap: () => _createNewRoutine(context, ref),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.add,
                            size: 22,
                            color: Color(0xFF000000),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Header separator line
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.06),
            ),
            // Routines content
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.routines.isEmpty
                      ? _buildEmptyState(context, lang)
                      : _buildRoutinesList(context, ref, state.routines, lang, Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLanguage lang) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 64,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              lang == AppLanguage.th
                  ? 'ยังไม่มีตารางฝึกส่วนตัว'
                  : 'No routines created yet',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              lang == AppLanguage.th
                  ? 'สร้างแม่แบบตารางฝึกเพื่อใช้อ้างอิงการฝึกซ้อม หรือสแกน QR Code จากเพื่อนเพื่อนำมาใช้งานได้ทันที'
                  : 'Create custom routine templates to start workouts quickly, or scan a friend\'s QR Code to import.',
              style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutinesList(
    BuildContext context,
    WidgetRef ref,
    List<RoutineWithDetails> routines,
    AppLanguage lang,
    Color accent,
  ) {


    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: routines.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = routines[index];
        final routine = item.routine;
        final exercises = item.exercises;

        final gradients = [
          const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFB91C1C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF047857)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFD97706)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ];
        final gradient = gradients[index % gradients.length];

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1B1F1B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Routine Header Image Banner
              SizedBox(
                height: 75,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        RoutineImageHelper.getImageUrl(
                          routine.name,
                          exercises.map((e) => e.exercise.name).toList(),
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(gradient: gradient),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.15),
                              const Color(0xFF1B1F1B),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                routine.name,
                                style: GoogleFonts.barlowCondensed(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFF2F5EF),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                lang == AppLanguage.th
                                    ? '${exercises.length} ท่าออกกำลังกาย'
                                    : '${exercises.length} exercises',
                                style: GoogleFonts.sarabun(
                                  fontSize: 12,
                                  color: const Color(0xFF7C8A7C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Actions buttons Row
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Edit button
                            GestureDetector(
                              onTap: () => _editRoutine(context, item),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.25),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 17,
                                  color: accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // QR share button
                            GestureDetector(
                              onTap: () => _shareRoutineAsQr(context, item, lang),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E211F),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.qr_code_2_outlined,
                                  size: 17,
                                  color: Color(0xFF8E9A8E),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Delete button
                            GestureDetector(
                              onTap: () => _confirmDeleteRoutine(context, ref, routine.id!, routine.name, lang),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 17,
                                  color: Color(0xFFF87171),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Exercise tag chips list
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...exercises.take(4).map((ex) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                ex.exercise.name,
                                style: GoogleFonts.sarabun(
                                  fontSize: 11,
                                  color: const Color(0xFF7C8A7C),
                                ),
                              ),
                            )),
                        if (exercises.length > 4)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '+${exercises.length - 4} ${lang == AppLanguage.th ? 'อื่นๆ' : 'more'}',
                              style: GoogleFonts.sarabun(
                                fontSize: 11,
                                color: const Color(0xFF5A6A5A),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Bottom actions: Start Workout
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: Text(
                          lang == AppLanguage.th ? 'เริ่มการฝึก' : 'Start Workout',
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: const Color(0xFF000000),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final exNames = exercises.map((e) => e.exercise.name).toList();
                          await ref.read(activeWorkoutProvider.notifier).startSessionFromTemplate(
                                routine.name,
                                exNames,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(lang == AppLanguage.th
                                    ? 'เริ่มเซสชันการฝึก ${routine.name} แล้ว!'
                                    : 'Started session ${routine.name}!'),
                                backgroundColor: Theme.of(context).colorScheme.primary,
                              ),
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteRoutine(
    BuildContext context,
    WidgetRef ref,
    int id,
    String name,
    AppLanguage lang,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang == AppLanguage.th ? 'ลบตารางฝึก?' : 'Delete Routine?'),
        content: Text(lang == AppLanguage.th
            ? 'คุณแน่ใจว่าต้องการลบตารางฝึก "$name" หรือไม่?'
            : 'Are you sure you want to delete the routine "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(lang == AppLanguage.th ? 'ยกเลิก' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1A0800),
              foregroundColor: const Color(0xFFFF5A3C),
            ),
            child: Text(lang == AppLanguage.th ? 'ลบ' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(routineProvider.notifier).deleteRoutine(id);
    }
  }

  void _shareRoutineAsQr(BuildContext context, RoutineWithDetails details, AppLanguage lang) {
    final Map<String, dynamic> data = {
      'name': details.routine.name,
      'exercises': details.exercises.map((ex) => {
        'name': ex.exercise.name,
        'sets': ex.sets.map((s) => {
          'weight_kg': s.weightKg,
          'reps': s.reps,
          'is_warmup': s.isWarmup,
        }).toList(),
      }).toList(),
    };
    final jsonStr = jsonEncode(data);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF171B17).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  lang == AppLanguage.th ? 'แชร์ตาราง' : 'Share Routine',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF2F5EF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${details.routine.name} · ${details.exercises.length} ${lang == AppLanguage.th ? 'ท่า' : 'exercises'}',
                  style: GoogleFonts.sarabun(
                    fontSize: 13,
                    color: const Color(0xFF7C8A7C),
                  ),
                ),
                const SizedBox(height: 20),
                // QR View Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: jsonStr,
                    version: QrVersions.auto,
                    size: 220.0,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // JSON text box representation
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0C0A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    jsonStr.length > 80 ? '${jsonStr.substring(0, 80)}...' : jsonStr,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: const Color(0xFF5A6A5A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 20),
                // Close button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: const Color(0xFF000000),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      lang == AppLanguage.th ? 'ปิด' : 'Close',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _importRoutineFromQr(BuildContext context, WidgetRef ref) {
    final lang = ref.read(languageProvider);
    bool hasScanned = false;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(lang == AppLanguage.th ? 'สแกนคิวอาร์โค้ด' : 'Scan QR Code'),
          ),
          body: MobileScanner(
            onDetect: (capture) async {
              if (hasScanned) return;

              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                hasScanned = true;
                final raw = barcodes.first.rawValue!;
                try {
                  final decoded = jsonDecode(raw) as Map<String, dynamic>;
                  final name = decoded['name'] as String;
                  final exJson = decoded['exercises'] as List<dynamic>;

                  final List<Map<String, dynamic>> exercises = [];
                  for (final item in exJson) {
                    final exMap = item as Map<String, dynamic>;
                    final setsJson = exMap['sets'] as List<dynamic>;

                    final List<Map<String, dynamic>> sets = [];
                    for (final s in setsJson) {
                      final sMap = s as Map<String, dynamic>;
                      sets.add({
                        'weight_kg': (sMap['weight_kg'] as num?)?.toDouble() ?? 0.0,
                        'reps': sMap['reps'] as int? ?? 10,
                        'is_warmup': sMap['is_warmup'] as bool? ?? false,
                      });
                    }

                    exercises.add({
                      'name': exMap['name'] as String,
                      'sets': sets,
                    });
                  }

                  await ref.read(routineProvider.notifier).addRoutine(name, exercises);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(lang == AppLanguage.th
                            ? 'นำเข้าตารางฝึก "$name" สำเร็จ!'
                            : 'Imported routine "$name" successfully!'),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    );
                    Navigator.pop(context); // Pop scanner
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(lang == AppLanguage.th
                            ? 'สแกนล้มเหลว: รูปแบบ QR Code ไม่ถูกต้อง'
                            : 'Scan failed: Invalid QR Code format'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    Navigator.pop(context); // Pop scanner
                  }
                }
              }
            },
          ),
        ),
      ),
    );
  }

  void _editRoutine(BuildContext context, RoutineWithDetails routineWithDetails) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CreateRoutineScreen(routineToEdit: routineWithDetails),
      ),
    );
  }

  void _createNewRoutine(BuildContext context, WidgetRef ref) {
    final lang = ref.read(languageProvider);
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AnimatedPadding(
              padding: MediaQuery.of(ctx).viewInsets,
              duration: const Duration(milliseconds: 100),
              curve: Curves.decelerate,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF101410).withValues(alpha: 0.94),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.09),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF333333),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      lang == AppLanguage.th ? 'สร้างตารางใหม่' : 'Create New Routine',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF2F5EF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: textController,
                      autofocus: true,
                      style: GoogleFonts.sarabun(
                        fontSize: 15,
                        color: const Color(0xFFF2F5EF),
                      ),
                      decoration: InputDecoration(
                        hintText: lang == AppLanguage.th ? 'ชื่อตารางฝึก เช่น Push Day' : 'Routine Name e.g. Push Day',
                        hintStyle: const TextStyle(color: Color(0xFF555555)),
                        filled: true,
                        fillColor: const Color(0xFF1E211F),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        // Cancel button
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
                        // Create button
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 48,
                            child: FilledButton(
                              onPressed: () {
                                final name = textController.text.trim();
                                if (name.isEmpty) return;
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => _CreateRoutineScreen(initialName: name),
                                  ),
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: const Color(0xFF000000),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                lang == AppLanguage.th ? 'สร้างตาราง' : 'Create Routine',
                                style: GoogleFonts.barlowCondensed(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
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
      },
    );
  }
}

class _CreateRoutineScreen extends ConsumerStatefulWidget {
  final String? initialName;
  final RoutineWithDetails? routineToEdit;

  const _CreateRoutineScreen({this.initialName, this.routineToEdit});

  @override
  ConsumerState<_CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends ConsumerState<_CreateRoutineScreen> {
  late final TextEditingController _nameCtrl;
  final List<Map<String, dynamic>> _exercises = [];

  @override
  void initState() {
    super.initState();
    final editItem = widget.routineToEdit;
    if (editItem != null) {
      _nameCtrl = TextEditingController(text: editItem.routine.name);
      for (final ex in editItem.exercises) {
        _exercises.add({
          'name': ex.exercise.name,
          'sets': <Map<String, dynamic>>[],
        });
      }
    } else {
      _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _addExercise() async {
    final name = await showAddExerciseSheet(context);
    if (name != null && name.trim().isNotEmpty) {
      setState(() {
        _exercises.add({
          'name': name.trim(),
          'sets': <Map<String, dynamic>>[],
        });
      });
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final lang = ref.read(languageProvider);
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang == AppLanguage.th ? 'กรุณากรอกชื่อตารางฝึก' : 'Please enter routine name'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang == AppLanguage.th ? 'กรุณาเพิ่มท่าออกกำลังกายอย่างน้อย 1 ท่า' : 'Please add at least 1 exercise'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (widget.routineToEdit != null) {
      await ref.read(routineProvider.notifier).updateRoutine(
        widget.routineToEdit!.routine.id!,
        name,
        _exercises,
      );
    } else {
      await ref.read(routineProvider.notifier).addRoutine(name, _exercises);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final theme = Theme.of(context);
    final textMuted = theme.textTheme.bodySmall?.color ?? Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.routineToEdit != null
              ? (lang == AppLanguage.th ? 'แก้ไขตารางฝึก' : 'Edit Routine')
              : (lang == AppLanguage.th ? 'สร้างตารางฝึกใหม่' : 'Create Routine'),
          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              lang == AppLanguage.th ? 'บันทึก' : 'Save',
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: lang == AppLanguage.th ? 'ชื่อตารางฝึก (เช่น Push Day)' : 'Routine Name (e.g. Push Day)',
                prefixIcon: const Icon(Icons.edit_note_outlined),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang == AppLanguage.th ? 'ท่าออกกำลังกายในตาราง' : 'Exercises',
                  style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.bold, color: textMuted),
                ),
                TextButton.icon(
                  onPressed: _addExercise,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(lang == AppLanguage.th ? 'เพิ่มท่า' : 'Add Exercise'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_exercises.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  lang == AppLanguage.th ? 'ยังไม่ได้เพิ่มท่าบริหารใดๆ' : 'No exercises added yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textMuted, fontStyle: FontStyle.italic),
                ),
              )
            else
              ..._exercises.asMap().entries.map((e) {
                final exIdx = e.key;
                final ex = e.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  color: const Color(0xFF1E211F),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${exIdx + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ex['name'] as String,
                            style: GoogleFonts.sarabun(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFF87171)),
                          onPressed: () => _removeExercise(exIdx),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
