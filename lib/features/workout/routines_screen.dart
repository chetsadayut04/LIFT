import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/providers/translation_provider.dart';
import '../../core/providers/unit_provider.dart';
import 'active_workout_provider.dart';
import 'active_workout_screen.dart';
import 'add_exercise_dialog.dart';
import 'routine_provider.dart';

class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(routineProvider);
    final lang = ref.watch(languageProvider);
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang == AppLanguage.th ? 'ตารางฝึกของฉัน' : 'My Routines',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_outlined),
            tooltip: lang == AppLanguage.th ? 'นำเข้าจาก QR' : 'Import from QR',
            onPressed: () => _importRoutineFromQr(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: lang == AppLanguage.th ? 'สร้างตารางใหม่' : 'New Routine',
            onPressed: () => _createNewRoutine(context, ref),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.routines.isEmpty
              ? _buildEmptyState(context, lang)
              : _buildRoutinesList(context, ref, state.routines, lang, accent),
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
    final theme = Theme.of(context);
    final textMuted = theme.textTheme.bodySmall?.color ?? Colors.grey;

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: routines.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = routines[index];
        final routine = item.routine;
        final exercises = item.exercises;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        routine.name,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.qr_code_2_outlined),
                      onPressed: () => _shareRoutineAsQr(context, item, lang),
                      tooltip: lang == AppLanguage.th ? 'แชร์ผ่าน QR' : 'Share QR',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _confirmDeleteRoutine(context, ref, routine.id!, routine.name, lang),
                      tooltip: lang == AppLanguage.th ? 'ลบตารางฝึก' : 'Delete Routine',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  lang == AppLanguage.th
                      ? '${exercises.length} ท่าออกกำลังกาย | ${exercises.fold(0, (sum, ex) => sum + ex.sets.length)} เซ็ตรวม'
                      : '${exercises.length} exercises | ${exercises.fold(0, (sum, ex) => sum + ex.sets.length)} total sets',
                  style: TextStyle(color: textMuted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ...exercises.take(3).map((ex) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 12, color: accent),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ex.exercise.name,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            lang == AppLanguage.th
                                ? '${ex.sets.length} เซ็ต'
                                : '${ex.sets.length} sets',
                            style: TextStyle(color: textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    )),
                if (exercises.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 18),
                    child: Text(
                      lang == AppLanguage.th
                          ? 'และอีก ${exercises.length - 3} ท่า...'
                          : 'and ${exercises.length - 3} more...',
                      style: TextStyle(color: textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
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
                                backgroundColor: accent,
                              ),
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
                            );
                          }
                        },
                        icon: const Icon(Icons.play_arrow_outlined, size: 18),
                        label: Text(lang == AppLanguage.th ? 'เริ่มตารางฝึกนี้' : 'Start Routine'),
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
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final bg = theme.colorScheme.surface;
        final border = theme.colorScheme.outline;
        final primaryText = theme.textTheme.bodyLarge?.color ?? Colors.white;

        return AlertDialog(
          backgroundColor: bg,
          title: Text(
            lang == AppLanguage.th ? 'แชร์ตารางฝึก: ${details.routine.name}' : 'Share Routine: ${details.routine.name}',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: QrImageView(
                  data: jsonStr,
                  version: QrVersions.auto,
                  size: 220.0,
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                lang == AppLanguage.th
                    ? 'ให้เพื่อนเปิดกล้องสแกน QR Code นี้ในหน้า "ตารางฝึกของฉัน" เพื่อคัดลอกตารางฝึกเข้าเครื่องทันที'
                    : 'Ask your friend to scan this QR Code in their "My Routines" screen to import it.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(lang == AppLanguage.th ? 'ปิด' : 'Close'),
              ),
            ),
          ],
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

  void _createNewRoutine(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _CreateRoutineScreen()),
    );
  }
}

class _CreateRoutineScreen extends ConsumerStatefulWidget {
  const _CreateRoutineScreen();

  @override
  ConsumerState<_CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends ConsumerState<_CreateRoutineScreen> {
  final _nameCtrl = TextEditingController();
  final List<Map<String, dynamic>> _exercises = [];

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
          'sets': [
            {'weight_kg': 0.0, 'reps': 10, 'is_warmup': false},
            {'weight_kg': 0.0, 'reps': 10, 'is_warmup': false},
            {'weight_kg': 0.0, 'reps': 10, 'is_warmup': false},
          ],
        });
      });
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  void _addSetToExercise(int exIndex) {
    setState(() {
      final sets = _exercises[exIndex]['sets'] as List<Map<String, dynamic>>;
      sets.add({'weight_kg': 0.0, 'reps': 10, 'is_warmup': false});
    });
  }

  void _removeSetFromExercise(int exIndex, int setIndex) {
    setState(() {
      final sets = _exercises[exIndex]['sets'] as List<Map<String, dynamic>>;
      if (sets.length > 1) {
        sets.removeAt(setIndex);
      }
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

    await ref.read(routineProvider.notifier).addRoutine(name, _exercises);
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
          lang == AppLanguage.th ? 'สร้างตารางฝึกใหม่' : 'Create Routine',
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
                final sets = ex['sets'] as List<Map<String, dynamic>>;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${exIdx + 1}. ${ex['name']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                              onPressed: () => _removeExercise(exIdx),
                            ),
                          ],
                        ),
                        const Divider(),
                        ...sets.asMap().entries.map((se) {
                          final setIdx = se.key;
                          final s = se.value;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 48,
                                  child: Text(
                                    'Set ${setIdx + 1}',
                                    style: TextStyle(color: textMuted, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      hintText: lang == AppLanguage.th ? 'น้ำหนัก' : 'Weight',
                                      suffixText: lang == AppLanguage.th ? ' กก.' : ' kg',
                                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      fillColor: Colors.transparent,
                                    ),
                                    onChanged: (val) {
                                      s['weight_kg'] = double.tryParse(val) ?? 0.0;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      hintText: lang == AppLanguage.th ? 'ครั้ง' : 'Reps',
                                      suffixText: lang == AppLanguage.th ? ' ครั้ง' : ' reps',
                                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      fillColor: Colors.transparent,
                                    ),
                                    onChanged: (val) {
                                      s['reps'] = int.tryParse(val) ?? 10;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (sets.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.grey),
                                    onPressed: () => _removeSetFromExercise(exIdx, setIdx),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _addSetToExercise(exIdx),
                            icon: const Icon(Icons.add_circle_outline, size: 14),
                            label: Text(
                              lang == AppLanguage.th ? 'เพิ่มเซ็ต' : 'Add Set',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
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
