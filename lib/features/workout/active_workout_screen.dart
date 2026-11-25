import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/unit_provider.dart';
import '../../core/providers/translation_provider.dart';
import '../../core/providers/tab_provider.dart';
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
      final cleanName = name.trim();
      final currentExercises = ref.read(activeWorkoutProvider).exercises;
      final isDuplicate = currentExercises.any(
        (e) => e.exercise.name.toLowerCase() == cleanName.toLowerCase(),
      );
      if (isDuplicate) {
        final lang = ref.read(languageProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang == AppLanguage.th
                  ? 'ท่า "$cleanName" มีอยู่ในการฝึกวันนี้แล้ว คุณสามารถเพิ่มเซ็ตในท่านั้นได้ทันที'
                  : '"$cleanName" is already added. You can add sets to it directly.',
            ),
            backgroundColor: Colors.orangeAccent.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }
      try {
        await ref.read(activeWorkoutProvider.notifier).addExercise(cleanName);
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
    BuildContext context,
    WidgetRef ref,
    String? currentName,
  ) async {
    final lang = ref.read(languageProvider);
    final controller = TextEditingController(text: currentName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          lang == AppLanguage.th ? 'ตั้งชื่อ Workout' : 'Name Workout',
        ),
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
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
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
    final textSec =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final textMuted =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    final border = Theme.of(context).colorScheme.outline;

    if (state.session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(lang.tr('home_start'))),
        body: Center(
          child: FilledButton.icon(
            onPressed: () =>
                ref.read(activeWorkoutProvider.notifier).startSession(),
            icon: const Icon(Icons.fitness_center),
            label: Text(lang.tr('home_start')),
          ),
        ),
      );
    }

    final displayTitle = state.session!.name ?? state.session!.displayDate;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: lang == AppLanguage.th ? 'ย้อนกลับ' : 'Back',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              ref.read(activeTabProvider.notifier).state = 0;
              Navigator.maybePop(context);
            }
          },
        ),
        title: readOnly
            ? Text(displayTitle)
            : GestureDetector(
                onTap: () => _renameSession(context, ref, state.session!.name),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        displayTitle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/empty_workout.webp',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                      cacheWidth: (120 * MediaQuery.devicePixelRatioOf(context)).round(),
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.fitness_center,
                        size: 40,
                        color: border,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lang.tr('workout_no_exercises'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textSec,
                    ),
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
          : Column(
              children: [
                _WorkoutTelemetryStrip(
                  exercises: state.exercises,
                  lang: lang,
                  readOnly: readOnly,
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
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
                    onAddSet: (weight, reps, isWarmup) => runSafe(
                      () => ref
                          .read(activeWorkoutProvider.notifier)
                          .addSet(
                            ex.exercise.id!,
                            weight,
                            reps,
                            isWarmup: isWarmup,
                          ),
                    ),
                    onDeleteSet: (setId) => runSafe(
                      () => ref
                          .read(activeWorkoutProvider.notifier)
                          .deleteSet(ex.exercise.id!, setId),
                    ),
                    onDeleteExercise: () => runSafe(
                      () => ref
                          .read(activeWorkoutProvider.notifier)
                          .deleteExercise(ex.exercise.id!),
                    ),
                    onRenameExercise: (name) => runSafe(
                      () => ref
                          .read(activeWorkoutProvider.notifier)
                          .renameExercise(ex.exercise.id!, name),
                    ),
                    onUpdateRepRange: (repMin, repMax) => runSafe(
                      () => ref
                          .read(activeWorkoutProvider.notifier)
                          .updateRepRange(ex.exercise.id!, repMin, repMax),
                    ),
                    onAfterAdd: () => _showRestTimer(context, ref),
                  ),
                );
              },
                  ),
                ),
              ],
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
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final textSec =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final textMuted =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

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
                              child: Icon(
                                Icons.drag_handle,
                                size: 18,
                                color: textMuted,
                              ),
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
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_horiz,
                              size: 18,
                              color: textMuted,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            color: AppColors.surfaceElevated,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            onSelected: (value) {
                              if (value == 'rep_range') {
                                _showRepRangeDialog(
                                  context,
                                  lang,
                                  textSec,
                                  textMuted,
                                );
                              } else if (value == 'rename') {
                                _showRenameDialog(context, ex.name, lang);
                              } else if (value == 'delete') {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text(
                                      lang.tr('dialog_delete_exercise'),
                                    ),
                                    content: Text(
                                      '${lang.tr('dialog_delete_exercise_desc')} "${ex.name}"?',
                                    ),
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
                                          backgroundColor: const Color(
                                            0xFF1A0800,
                                          ),
                                          foregroundColor: const Color(
                                            0xFFFF5A3C,
                                          ),
                                        ),
                                        child: Text(lang.tr('btn_delete')),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'rep_range',
                                child: Text(
                                  lang == AppLanguage.th
                                      ? 'ตั้งช่วง Rep เป้าหมาย'
                                      : 'Target Rep Range',
                                ),
                              ),
                              PopupMenuItem(
                                value: 'rename',
                                child: Text(
                                  lang == AppLanguage.th
                                      ? 'เปลี่ยนชื่อท่า'
                                      : 'Rename Exercise',
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  lang.tr('btn_delete'),
                                  style: const TextStyle(
                                    color: AppColors.tertiary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    // Sets table
                    if (sets.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      // Pro Set Matrix Header (Hevy / Strong style)
                      Row(
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text(
                              'SET',
                              style: GoogleFonts.barlowCondensed(
                                fontSize: 11,
                                color: textMuted,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 78,
                            child: Text(
                              'PREVIOUS',
                              style: GoogleFonts.barlowCondensed(
                                fontSize: 11,
                                color: textMuted,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              unit.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.barlowCondensed(
                                fontSize: 11,
                                color: textMuted,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 46,
                            child: Text(
                              'REPS',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.barlowCondensed(
                                fontSize: 11,
                                color: textMuted,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 30,
                            child: Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Pro Set Matrix Rows
                      ...() {
                        var warmupIdx = 0;
                        var workingIdx = 0;
                        final lastWarmup =
                            exerciseWithSets.lastSessionWarmupSets;
                        final lastWorking = exerciseWithSets.lastSessionSets;

                        return sets.map((s) {
                          final ({double weight, int reps})? prevSet;
                          final int setDisplayNumber;
                          if (s.isWarmup) {
                            prevSet = warmupIdx < lastWarmup.length
                                ? lastWarmup[warmupIdx]
                                : null;
                            warmupIdx++;
                            setDisplayNumber = warmupIdx;
                          } else {
                            prevSet = workingIdx < lastWorking.length
                                ? lastWorking[workingIdx]
                                : null;
                            workingIdx++;
                            setDisplayNumber = workingIdx;
                          }
                          final prevStr = prevSet != null
                              ? '${prevSet.weight.display(isLbs)} × ${prevSet.reps}'
                              : '—';

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            padding: const EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated.withValues(
                                alpha: 0.45,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.border.withValues(alpha: 0.6),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Set Number or Warmup Badge
                                SizedBox(
                                  width: 30,
                                  child: s.isWarmup
                                      ? Container(
                                          width: 22,
                                          height: 22,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppColors.warning.withValues(
                                              alpha: 0.18,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'W',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.warning,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: 22,
                                          height: 22,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: AppColors.border,
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            '$setDisplayNumber',
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: textSec,
                                            ),
                                          ),
                                        ),
                                ),
                                // Previous Session Performance
                                SizedBox(
                                  width: 78,
                                  child: Text(
                                    prevStr,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      color: textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                // Weight
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        s.weightKg.display(isLbs),
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: s.isWarmup
                                              ? textSec
                                              : textPrimary,
                                        ),
                                      ),
                                      if (!s.isWarmup &&
                                          prKg != null &&
                                          s.weightKg >= prKg) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                          child: const Text(
                                            'PR',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF000000),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // Reps
                                SizedBox(
                                  width: 46,
                                  child: Text(
                                    '${s.reps}',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          s.isWarmup ? textSec : textPrimary,
                                    ),
                                  ),
                                ),
                                // Logged Checkmark / Delete button
                                SizedBox(
                                  width: 30,
                                  child: readOnly
                                      ? Container(
                                          width: 24,
                                          height: 24,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Icon(
                                            Icons.check_rounded,
                                            size: 14,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : GestureDetector(
                                          onTap: () => onDeleteSet(s.id!),
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.18),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.35),
                                                width: 1,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.check_rounded,
                                              size: 14,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          );
                        });
                      }(),
                      const SizedBox(height: 12),
                    ] else
                      const SizedBox(height: 12),

                    if (!readOnly)
                      AddSetForm(
                        onAdd: onAddSet,
                        onAfterAdd: onAfterAdd,
                        previousSets: sets
                            .map((s) => (
                                  weight: s.weightKg,
                                  reps: s.reps,
                                  isWarmup: s.isWarmup,
                                ))
                            .toList(),
                        lastSessionSets: exerciseWithSets.lastSessionSets,
                        lastSessionWarmupSets:
                            exerciseWithSets.lastSessionWarmupSets,
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

  void _showRepRangeDialog(
    BuildContext context,
    AppLanguage lang,
    Color textSec,
    Color textMuted,
  ) {
    int repMin = exerciseWithSets.repMin;
    int repMax = exerciseWithSets.repMax;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Widget stepper(
            String label,
            int value,
            VoidCallback onDec,
            VoidCallback onInc,
          ) => Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  label,
                  style: TextStyle(fontSize: 13, color: textSec),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove, size: 16),
                onPressed: onDec,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
            title: Text(
              '${lang.tr('dialog_target_title')} ${exerciseWithSets.exercise.name}',
              style: const TextStyle(fontSize: 15),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rep range',
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
                const SizedBox(height: 8),
                stepper(
                  'Min',
                  repMin,
                  () => setDialogState(() {
                    if (repMin > 1) repMin--;
                  }),
                  () => setDialogState(() {
                    if (repMin < repMax) repMin++;
                  }),
                ),
                stepper(
                  'Max',
                  repMax,
                  () => setDialogState(() {
                    if (repMax > repMin) repMax--;
                  }),
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

  void _showRenameDialog(
    BuildContext context,
    String currentName,
    AppLanguage lang,
  ) {
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

class _WorkoutTelemetryStrip extends ConsumerWidget {
  final List<ExerciseWithSets> exercises;
  final AppLanguage lang;
  final bool readOnly;

  const _WorkoutTelemetryStrip({
    required this.exercises,
    required this.lang,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLbs = ref.watch(isLbsProvider);
    final unit = isLbs ? 'lbs' : 'kg';
    final timer = ref.watch(restTimerProvider);
    final timerNotifier = ref.read(restTimerProvider.notifier);

    int workingSets = 0;
    double totalVolumeKg = 0;
    for (final ex in exercises) {
      for (final s in ex.sets) {
        if (!s.isWarmup) {
          workingSets++;
          totalVolumeKg += s.weightKg * s.reps;
        }
      }
    }
    final displayVol = isLbs ? totalVolumeKg * kgToLbs : totalVolumeKg;
    final volStr = displayVol >= 1000
        ? '${(displayVol / 1000).toStringAsFixed(1)}k'
        : displayVol.toStringAsFixed(0);

    final mins = timer.secondsLeft ~/ 60;
    final secs = timer.secondsLeft % 60;
    final timerStr =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              _TelemetryMetric(
                label: lang == AppLanguage.th ? 'ท่า' : 'EXERCISES',
                value: '${exercises.length}',
              ),
              _TelemetryMetric(
                label: lang == AppLanguage.th ? 'เซ็ตจริง' : 'SETS',
                value: '$workingSets',
              ),
              _TelemetryMetric(
                label: lang == AppLanguage.th
                    ? 'วอลุ่ม ($unit)'
                    : 'VOLUME ($unit)',
                value: volStr,
                highlight: true,
              ),
            ],
          ),
          if (!readOnly && timer.isRunning) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.timer_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    lang == AppLanguage.th ? 'พักเซ็ต' : 'REST',
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timerStr,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  _MiniTimerBtn(
                    label: '-15s',
                    onTap: () => timerNotifier.adjust(-15),
                  ),
                  const SizedBox(width: 6),
                  _MiniTimerBtn(
                    label: '+15s',
                    onTap: () => timerNotifier.adjust(15),
                  ),
                  const SizedBox(width: 6),
                  _MiniTimerBtn(
                    label: 'Skip',
                    accent: true,
                    onTap: () => timerNotifier.reset(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TelemetryMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _TelemetryMetric({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.barlowCondensed(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: AppColors.textMuted,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: highlight ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTimerBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool accent;

  const _MiniTimerBtn({
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: accent
              ? AppColors.primary.withValues(alpha: 0.16)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: accent
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: accent ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}