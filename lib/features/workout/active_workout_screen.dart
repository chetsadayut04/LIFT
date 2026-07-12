import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/unit_provider.dart';
import 'active_workout_provider.dart';
import 'add_exercise_dialog.dart';
import 'add_set_form.dart';
import 'rest_timer_provider.dart';
import 'rest_timer_widget.dart';

const _kAccent = Color(0xFFC6FF3D);
const _kTextPrimary = Color(0xFFF2F5EF);
const _kTextSec = Color(0xFFB8C2B4);
const _kTextMuted = Color(0xFF7C8A7C);
const _kBorder = Color(0xFF262A24);

class ActiveWorkoutScreen extends ConsumerWidget {
  final bool readOnly;
  const ActiveWorkoutScreen({super.key, this.readOnly = false});

  void _showRestTimer(BuildContext context, WidgetRef ref) {
    ref.read(restTimerProvider.notifier).reset(seconds: 90);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const RestTimerBottomSheet(),
    );
  }

  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final name = await showAddExerciseSheet(context);
    if (name != null && context.mounted) {
      await ref.read(activeWorkoutProvider.notifier).addExercise(name);
    }
  }

  Future<void> _renameSession(
      BuildContext context, WidgetRef ref, String? currentName) async {
    final controller = TextEditingController(text: currentName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ตั้งชื่อ Workout'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'เช่น Chest Day, Leg Day...'),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      await ref.read(activeWorkoutProvider.notifier).renameSession(name);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeWorkoutProvider);

    if (state.session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: Center(
          child: FilledButton.icon(
            onPressed: () => ref.read(activeWorkoutProvider.notifier).startSession(),
            icon: const Icon(Icons.fitness_center),
            label: const Text('เริ่ม Workout'),
          ),
        ),
      );
    }

    final displayTitle = state.session!.name ?? state.session!.displayDate;

    return Scaffold(
      appBar: AppBar(
        title: readOnly
            ? Text(displayTitle)
            : GestureDetector(
                onTap: () => _renameSession(context, ref, state.session!.name),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text(displayTitle, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 6),
                    const Icon(Icons.edit_outlined, size: 14, color: _kTextMuted),
                  ],
                ),
              ),
        actions: [
          if (!readOnly)
            IconButton(
              icon: const Icon(Icons.timer_outlined),
              tooltip: 'พัก',
              onPressed: () => _showRestTimer(context, ref),
            ),
        ],
      ),
      body: state.exercises.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fitness_center, size: 40, color: _kBorder),
                  const SizedBox(height: 16),
                  const Text(
                    'ยังไม่มีท่า',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kTextSec),
                  ),
                  const SizedBox(height: 6),
                  if (!readOnly) ...[
                    const Text(
                      'กด + เพื่อเพิ่มท่าออกกำลังกาย',
                      style: TextStyle(fontSize: 13, color: _kTextMuted),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _addExercise(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('เพิ่มท่า'),
                    ),
                  ],
                ],
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) => ref
                  .read(activeWorkoutProvider.notifier)
                  .reorderExercises(oldIndex, newIndex),
              itemCount: state.exercises.length,
              itemBuilder: (_, i) {
                final ex = state.exercises[i];
                return Padding(
                  key: ValueKey(ex.exercise.id),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ExerciseCard(
                    exerciseWithSets: ex,
                    readOnly: readOnly,
                    index: i,
                    onAddSet: (weight, reps, isWarmup) async {
                      await ref
                          .read(activeWorkoutProvider.notifier)
                          .addSet(ex.exercise.id!, weight, reps, isWarmup: isWarmup);
                    },
                    onDeleteSet: (setId) => ref
                        .read(activeWorkoutProvider.notifier)
                        .deleteSet(ex.exercise.id!, setId),
                    onDeleteExercise: () => ref
                        .read(activeWorkoutProvider.notifier)
                        .deleteExercise(ex.exercise.id!),
                    onRenameExercise: (name) => ref
                        .read(activeWorkoutProvider.notifier)
                        .renameExercise(ex.exercise.id!, name),
                    onUpdateRepRange: (repMin, repMax) => ref
                        .read(activeWorkoutProvider.notifier)
                        .updateRepRange(ex.exercise.id!, repMin, repMax),
                    onAfterAdd: () => _showRestTimer(context, ref),
                  ),
                );
              },
            ),
      floatingActionButton: (!readOnly && state.session != null)
          ? FloatingActionButton.extended(
              onPressed: () => _addExercise(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('เพิ่มท่า'),
              backgroundColor: _kAccent,
              foregroundColor: const Color(0xFF050A05),
            )
          : null,
    );
  }
}

class _ExerciseCard extends ConsumerWidget {
  final ExerciseWithSets exerciseWithSets;
  final bool readOnly;
  final int index;
  final void Function(double weight, int reps, bool isWarmup) onAddSet;
  final void Function(int setId) onDeleteSet;
  final VoidCallback onDeleteExercise;
  final void Function(String name) onRenameExercise;
  final void Function(int repMin, int repMax) onUpdateRepRange;
  final VoidCallback? onAfterAdd;

  const _ExerciseCard({
    required this.exerciseWithSets,
    this.readOnly = false,
    required this.index,
    required this.onAddSet,
    required this.onDeleteSet,
    required this.onDeleteExercise,
    required this.onRenameExercise,
    required this.onUpdateRepRange,
    this.onAfterAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLbs = ref.watch(isLbsProvider);
    final unit = isLbs ? 'lbs' : 'kg';
    final ex = exerciseWithSets.exercise;
    final sets = exerciseWithSets.sets;
    final prKg = exerciseWithSets.prKg;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: _kAccent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            // Exercise header
            Row(
              children: [
                if (!readOnly)
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.drag_handle, size: 18, color: _kTextMuted),
                    ),
                  ),
                Expanded(
                  child: Text(
                    ex.name,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: _kTextPrimary,
                    ),
                  ),
                ),
                if (!readOnly)
                  GestureDetector(
                    onTap: () => _showRepRangeDialog(context),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8, right: 4),
                      child: Icon(Icons.tune, size: 15, color: _kTextMuted),
                    ),
                  ),
                if (!readOnly)
                  GestureDetector(
                    onTap: () => _showRenameDialog(context, ex.name),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 4, right: 4),
                      child: Icon(Icons.edit_outlined, size: 15, color: _kTextMuted),
                    ),
                  ),
                if (!readOnly)
                  GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('ลบท่า?'),
                        content: Text('ลบ "${ex.name}" และ sets ทั้งหมด?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('ยกเลิก'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onDeleteExercise();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1A0800),
                              foregroundColor: const Color(0xFFFF5A3C),
                            ),
                            child: const Text('ลบ'),
                          ),
                        ],
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline, size: 17, color: _kTextMuted),
                    ),
                  ),
              ],
            ),

            // Sets table
            if (sets.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(
                    width: 36,
                    child: Text('Set',
                        style: TextStyle(fontSize: 11, color: _kTextSec, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    child: Text(unit,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: _kTextSec, fontWeight: FontWeight.w600)),
                  ),
                  const Expanded(
                    child: Text('Reps',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: _kTextSec, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    child: Tooltip(
                      message: 'น้ำหนักสูงสุดที่ประเมินว่ายกได้ 1 ครั้ง\nสูตร Epley: น้ำหนัก × (1 + reps/30)',
                      triggerMode: TooltipTriggerMode.tap,
                      showDuration: const Duration(seconds: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('e1RM',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: _kTextSec, fontWeight: FontWeight.w600)),
                          SizedBox(width: 2),
                          Icon(Icons.info_outline, size: 10, color: _kTextMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 28),
                ],
              ),
              const SizedBox(height: 6),
              ...sets.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: s.isWarmup
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF9F1C).withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('W',
                                      style: TextStyle(
                                          fontSize: 11, color: Color(0xFFFF9F1C), fontWeight: FontWeight.w700)),
                                )
                              : Text('${s.setNumber}',
                                  style: const TextStyle(fontSize: 13, color: _kTextSec)),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                s.weightKg.display(isLbs),
                                style: GoogleFonts.jetBrainsMono(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: s.isWarmup ? _kTextSec : _kTextPrimary),
                              ),
                              if (!s.isWarmup && prKg != null && s.weightKg >= prKg) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF5A3C),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text('PR',
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1A0800))),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${s.reps}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: s.isWarmup ? _kTextSec : _kTextPrimary),
                          ),
                        ),
                        Expanded(
                          child: s.isWarmup
                              ? const SizedBox.shrink()
                              : Text(
                                  fmtNum(calc1RM(s.weightKg, s.reps) * (isLbs ? kgToLbs : 1)),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.jetBrainsMono(fontSize: 12, color: _kTextMuted),
                                ),
                        ),
                        SizedBox(
                          width: 28,
                          child: readOnly
                              ? const SizedBox.shrink()
                              : GestureDetector(
                                  onTap: () => onDeleteSet(s.id!),
                                  child: const Icon(Icons.close, size: 14, color: _kTextMuted),
                                ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 14),
            ] else
              const SizedBox(height: 12),

            if (!readOnly)
              AddSetForm(
                onAdd: onAddSet,
                onAfterAdd: onAfterAdd,
                previousSets: sets.map((s) => (weight: s.weightKg, reps: s.reps)).toList(),
                lastSessionSets: exerciseWithSets.lastSessionSets,
                repMin: exerciseWithSets.repMin,
                repMax: exerciseWithSets.repMax,
              ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRepRangeDialog(BuildContext context) {
    int repMin = exerciseWithSets.repMin;
    int repMax = exerciseWithSets.repMax;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Widget stepper(String label, int value, VoidCallback onDec, VoidCallback onInc) =>
              Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(label, style: const TextStyle(fontSize: 13, color: _kTextSec)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove, size: 16),
                    onPressed: onDec,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  SizedBox(
                    width: 32,
                    child: Text('$value',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: onInc,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              );

          return AlertDialog(
            title: Text('เป้าหมาย ${exerciseWithSets.exercise.name}',
                style: const TextStyle(fontSize: 15)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rep range', style: TextStyle(fontSize: 11, color: _kTextMuted)),
                const SizedBox(height: 8),
                stepper(
                  'Min',
                  repMin,
                  () => setDialogState(() { if (repMin > 1) repMin--; }),
                  () => setDialogState(() { if (repMin < repMax) repMin++; }),
                ),
                stepper(
                  'Max',
                  repMax,
                  () => setDialogState(() { if (repMax > repMin) repMax--; }),
                  () => setDialogState(() => repMax++),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ยกเลิก'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onUpdateRepRange(repMin, repMax);
                },
                child: const Text('บันทึก'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRenameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เปลี่ยนชื่อท่า'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (v) {
            onRenameExercise(v);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              onRenameExercise(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }
}
