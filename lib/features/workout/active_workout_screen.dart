import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/unit_provider.dart';
import '../../core/providers/translation_provider.dart';
import 'active_workout_provider.dart';
import 'add_exercise_dialog.dart';
import 'add_set_form.dart';
import 'rest_timer_provider.dart';
import 'rest_timer_widget.dart';

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
      try {
        await ref.read(activeWorkoutProvider.notifier).addExercise(name);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding exercise: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _renameSession(
      BuildContext context, WidgetRef ref, String? currentName) async {
    final lang = ref.read(languageProvider);
    final controller = TextEditingController(text: currentName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(lang == AppLanguage.th ? 'ตั้งชื่อ Workout' : 'Name Workout'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: lang.tr('dialog_program_hint')),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(lang.tr('btn_cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(lang.tr('btn_save')),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      try {
        await ref.read(activeWorkoutProvider.notifier).renameSession(name);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error renaming workout: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeWorkoutProvider);
    final lang = ref.watch(languageProvider);

    Future<void> runSafe(Future<void> Function() action) async {
      try {
        await action();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }

    final accent = Theme.of(context).colorScheme.primary;
    final textSec = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final textMuted = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    final border = Theme.of(context).colorScheme.outline;

    if (state.session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(lang.tr('home_start'))),
        body: Center(
          child: FilledButton.icon(
            onPressed: () => ref.read(activeWorkoutProvider.notifier).startSession(),
            icon: const Icon(Icons.fitness_center),
            label: Text(lang.tr('home_start')),
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
                    Icon(Icons.edit_outlined, size: 14, color: textMuted),
                  ],
                ),
              ),
        actions: [
          if (!readOnly)
            IconButton(
              icon: const Icon(Icons.timer_outlined),
              tooltip: lang.tr('label_rest'),
              onPressed: () => _showRestTimer(context, ref),
            ),
        ],
      ),
      body: state.exercises.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fitness_center, size: 40, color: border),
                  const SizedBox(height: 16),
                  Text(
                    lang.tr('workout_no_exercises'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textSec),
                  ),
                  const SizedBox(height: 6),
                  if (!readOnly) ...[
                    Text(
                      lang.tr('workout_add_exercise_hint'),
                      style: TextStyle(fontSize: 13, color: textMuted),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _addExercise(context, ref),
                      icon: const Icon(Icons.add),
                      label: Text(lang.tr('workout_add_exercise')),
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
                    onAddSet: (weight, reps, isWarmup) => runSafe(() => ref
                        .read(activeWorkoutProvider.notifier)
                        .addSet(ex.exercise.id!, weight, reps, isWarmup: isWarmup)),
                    onDeleteSet: (setId) => runSafe(() => ref
                        .read(activeWorkoutProvider.notifier)
                        .deleteSet(ex.exercise.id!, setId)),
                    onDeleteExercise: () => runSafe(() => ref
                        .read(activeWorkoutProvider.notifier)
                        .deleteExercise(ex.exercise.id!)),
                    onRenameExercise: (name) => runSafe(() => ref
                        .read(activeWorkoutProvider.notifier)
                        .renameExercise(ex.exercise.id!, name)),
                    onUpdateRepRange: (repMin, repMax) => runSafe(() => ref
                        .read(activeWorkoutProvider.notifier)
                        .updateRepRange(ex.exercise.id!, repMin, repMax)),
                    onAfterAdd: () => _showRestTimer(context, ref),
                  ),
                );
              },
            ),
      floatingActionButton: (!readOnly && state.session != null)
          ? FloatingActionButton.extended(
              onPressed: () => _addExercise(context, ref),
              icon: const Icon(Icons.add),
              label: Text(lang.tr('workout_add_exercise')),
              backgroundColor: accent,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
    final lang = ref.watch(languageProvider);
    final ex = exerciseWithSets.exercise;
    final sets = exerciseWithSets.sets;
    final prKg = exerciseWithSets.prKg;

    final accent = Theme.of(context).colorScheme.primary;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final textSec = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final textMuted = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: accent),
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
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Icon(Icons.drag_handle, size: 18, color: textMuted),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            ex.name,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        if (!readOnly)
                          GestureDetector(
                            onTap: () => _showRepRangeDialog(context, lang, textSec, textMuted),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8, right: 4),
                              child: Icon(Icons.tune, size: 15, color: textMuted),
                            ),
                          ),
                        if (!readOnly)
                          GestureDetector(
                            onTap: () => _showRenameDialog(context, ex.name, lang),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4, right: 4),
                              child: Icon(Icons.edit_outlined, size: 15, color: textMuted),
                            ),
                          ),
                        if (!readOnly)
                          GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text(lang.tr('dialog_delete_exercise')),
                                content: Text('${lang.tr('dialog_delete_exercise_desc')} "${ex.name}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(lang.tr('btn_cancel')),
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
                                    child: Text(lang.tr('btn_delete')),
                                  ),
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(Icons.delete_outline, size: 17, color: textMuted),
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
                          SizedBox(
                            width: 36,
                            child: Text('Set',
                                style: TextStyle(fontSize: 11, color: textSec, fontWeight: FontWeight.w600)),
                          ),
                          Expanded(
                            child: Text(unit,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: textSec, fontWeight: FontWeight.w600)),
                          ),
                          Expanded(
                            child: Text('Reps',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: textSec, fontWeight: FontWeight.w600)),
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
                                          style: TextStyle(fontSize: 13, color: textSec)),
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
                                            color: s.isWarmup ? textSec : textPrimary),
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
                                        color: s.isWarmup ? textSec : textPrimary),
                                  ),
                                ),
                                SizedBox(
                                  width: 28,
                                  child: readOnly
                                      ? const SizedBox.shrink()
                                      : GestureDetector(
                                          onTap: () => onDeleteSet(s.id!),
                                          child: Icon(Icons.close, size: 14, color: textMuted),
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

  void _showRepRangeDialog(BuildContext context, AppLanguage lang, Color textSec, Color textMuted) {
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
                    child: Text(label, style: TextStyle(fontSize: 13, color: textSec)),
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
            title: Text('${lang.tr('dialog_target_title')} ${exerciseWithSets.exercise.name}',
                style: const TextStyle(fontSize: 15)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rep range', style: TextStyle(fontSize: 11, color: textMuted)),
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
                child: Text(lang.tr('btn_cancel')),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onUpdateRepRange(repMin, repMax);
                },
                child: Text(lang.tr('btn_save')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRenameDialog(BuildContext context, String currentName, AppLanguage lang) {
    final controller = TextEditingController(text: currentName);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.tr('dialog_rename_exercise')),
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
            child: Text(lang.tr('btn_cancel')),
          ),
          FilledButton(
            onPressed: () {
              onRenameExercise(controller.text);
              Navigator.pop(ctx);
            },
            child: Text(lang.tr('btn_save')),
          ),
        ],
      ),
    );
  }
}
