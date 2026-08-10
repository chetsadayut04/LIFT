import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/database/exercise_dao.dart';
import '../../core/database/session_dao.dart';
import '../../core/providers/unit_provider.dart';
import '../../core/providers/translation_provider.dart';
import '../../core/widgets/plate_stack.dart';
import '../workout/active_workout_provider.dart';
import '../workout/active_workout_screen.dart';
import 'home_provider.dart';
const _thaiDays = ['จันทร์', 'อังคาร', 'พุธ', 'พฤหัส', 'ศุกร์', 'เสาร์', 'อาทิตย์'];
const _thaiMonths = ['', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];

const _enDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _enMonths = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _fmtVol(double v, bool isLbs) {
  final val = isLbs ? v * kgToLbs : v;
  final unit = isLbs ? 'lbs' : 'kg';
  if (val >= 1000) {
    final k = val / 1000;
    return '${fmtNum(k)}k $unit';
  }
  return '${fmtNum(val)} $unit';
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeProvider);
    return Scaffold(
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _HomeBody(state: state),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  final HomeState state;
  const _HomeBody({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLbs = ref.watch(isLbsProvider);
    final lang = ref.watch(languageProvider);
    final now = DateTime.now();

    final accent = Theme.of(context).colorScheme.primary;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final textMuted = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    final divider = Theme.of(context).colorScheme.outline;

    final dayStr = lang == AppLanguage.th ? _thaiDays[now.weekday - 1] : _enDays[now.weekday - 1];
    final monthStr = lang == AppLanguage.th ? _thaiMonths[now.month] : _enMonths[now.month];
    final dateText = lang == AppLanguage.th ? '$dayStr  ${now.day} $monthStr' : '$dayStr, ${now.day} $monthStr';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top bar ──────────────────────────────────────────────
          Row(
            children: [
              Text(
                'LIFT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: textMuted,
                ),
              ),
              const Spacer(),
              Text(
                dateText,
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () => ref.read(isLbsProvider.notifier).toggle(),
                child: Row(
                  children: [
                    Text(
                      'kg',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isLbs ? textMuted : accent,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '·',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                    ),
                    Text(
                      'lbs',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isLbs ? accent : textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),

          // ── Session name / volume ─────────────────────────────────
          Text(
            state.sessionName ??
                (state.todayVolume > 0
                    ? _fmtVol(state.todayVolume, isLbs)
                    : lang.tr('home_ready')),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 38,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.5,
              height: 1,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // ── Timer row ─────────────────────────────────────────────
          _TimerRow(state: state),

          if (state.todayVolume > 0) ...[
            const SizedBox(height: 10),
            _VolumeSummaryRow(state: state, isLbs: isLbs),
          ],

          const SizedBox(height: 20),
          Divider(height: 1, thickness: 0.5, color: divider),
          const SizedBox(height: 16),

          // ── Today label ───────────────────────────────────────────
          Row(
            children: [
              Text(
                lang.tr('home_today'),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: textMuted,
                ),
              ),
              const Spacer(),
              if (state.streak > 0)
                Text(
                  '${state.streak} ${lang.tr('home_streak')}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Exercise list ─────────────────────────────────────────
          Expanded(
            child: _ExerciseList(state: state, isLbs: isLbs),
          ),

          const SizedBox(height: 16),

          // ── Action buttons ────────────────────────────────────────
          _buildActions(context, ref, lang, accent),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, AppLanguage lang, Color accent) {
    if (state.isFinishedToday) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () => _viewFinished(context, ref),
                child: Text(lang.tr('home_view_summary')),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: () => _reopen(context, ref),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined, size: 15),
                  const SizedBox(width: 6),
                  Text(lang.tr('home_edit')),
                ],
              ),
            ),
          ),
        ],
      );
    }
    if (state.hasSessionToday) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () => _continue(context, ref),
                child: Text(lang.tr('home_continue')),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: () => _finish(context, ref, lang, accent),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF5A3C),
                side: const BorderSide(color: Color(0xFFFF5A3C)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 16),
                  const SizedBox(width: 6),
                  Text(lang.tr('home_finish')),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: () => _start(context, ref, lang),
        child: Text(lang.tr('home_start')),
      ),
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref, AppLanguage lang) async {
    final result = await showDialog<({String? name, List<String> exercises})>(
      context: context,
      builder: (_) => const _WorkoutNameDialog(),
    );
    if (!context.mounted) return;
    final name = result?.name;
    final exercises = result?.exercises ?? [];
    if (exercises.isNotEmpty) {
      await ref.read(activeWorkoutProvider.notifier).startSessionFromTemplate(name, exercises);
    } else {
      await ref.read(activeWorkoutProvider.notifier).startSession(name: name);
    }
    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
      );
      ref.read(homeProvider.notifier).load();
    }
  }

  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    await ref.read(activeWorkoutProvider.notifier).loadTodaySession();
    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
      );
      ref.read(homeProvider.notifier).load();
    }
  }

  Future<void> _reopen(BuildContext context, WidgetRef ref) async {
    await ref.read(homeProvider.notifier).reopenSession();
    await ref.read(activeWorkoutProvider.notifier).loadTodaySession();
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
    );
    ref.read(homeProvider.notifier).load();
  }

  Future<void> _viewFinished(BuildContext context, WidgetRef ref) async {
    await ref.read(activeWorkoutProvider.notifier).loadTodaySession();
    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ActiveWorkoutScreen(readOnly: true),
        ),
      );
    }
  }

  Future<void> _finish(BuildContext context, WidgetRef ref, AppLanguage lang, Color accent) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang == AppLanguage.th ? 'เสร็จสิ้นการออกกำลังกาย?' : 'Finish Workout?'),
        content: Text(
          lang == AppLanguage.th 
              ? 'ข้อมูลทั้งหมดที่บันทึกไปจะถูกเก็บไว้เรียบร้อยแล้ว\nจะไม่สามารถเพิ่มท่าหรือ set ได้อีกสำหรับวันนี้'
              : 'All logged data is saved.\nYou will not be able to add exercises or sets today.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(lang.tr('btn_cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1A0800),
              foregroundColor: const Color(0xFFFF5A3C),
            ),
            child: Text(lang.tr('home_finish')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(activeWorkoutProvider.notifier).clearSession();
      await ref.read(homeProvider.notifier).finishSession();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: accent),
                const SizedBox(width: 8),
                Text(
                  lang.tr('home_finished_today_alert'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).cardTheme.color ?? const Color(0xFF1B1F1B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

// ─── Timer Row ────────────────────────────────────────────────────────────────

class _TimerRow extends ConsumerStatefulWidget {
  final HomeState state;
  const _TimerRow({required this.state});

  @override
  ConsumerState<_TimerRow> createState() => _TimerRowState();
}

class _TimerRowState extends ConsumerState<_TimerRow> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(_TimerRow old) {
    super.didUpdateWidget(old);
    if (old.state.sessionStartedAt != widget.state.sessionStartedAt ||
        old.state.sessionFinishedAt != widget.state.sessionFinishedAt) {
      _stopTimer();
      _startTimer();
    }
  }

  void _startTimer() {
    final s = widget.state;
    if (s.sessionStartedAt != null && s.sessionFinishedAt == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _now = DateTime.now());
      });
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final hasSession = s.sessionStartedAt != null;
    final isActive = hasSession && s.sessionFinishedAt == null;

    final accent = Theme.of(context).colorScheme.primary;
    final textMuted = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    String timerStr = '--:--';
    if (hasSession) {
      final startDt = DateTime.fromMillisecondsSinceEpoch(s.sessionStartedAt!);
      final endDt = s.sessionFinishedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(s.sessionFinishedAt!)
          : _now;
      timerStr = _fmt(endDt.difference(startDt));
    }

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? accent : textMuted,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          timerStr,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: isActive ? accent : textMuted,
            shadows: isActive
                ? [Shadow(color: accent.withValues(alpha: 0.4), blurRadius: 14)]
                : null,
          ),
        ),
      ],
    );
  }
}

// ─── Workout Name Dialog ──────────────────────────────────────────────────────

typedef _Template = ({String name, int sessionId, List<String> exercises});

class _WorkoutNameDialog extends ConsumerStatefulWidget {
  const _WorkoutNameDialog();

  @override
  ConsumerState<_WorkoutNameDialog> createState() => _WorkoutNameDialogState();
}

class _WorkoutNameDialogState extends ConsumerState<_WorkoutNameDialog> {
  final _ctrl = TextEditingController();
  List<_Template> _templates = [];
  String? _selectedName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sessionDao = SessionDao();
    final exerciseDao = ExerciseDao();
    final sessions = await sessionDao.getRecentNamedSessions(limit: 20);
    final templates = await Future.wait(sessions.map((s) async {
      final exs = await exerciseDao.getBySession(s.id!);
      return (name: s.name!, sessionId: s.id!, exercises: exs.map((e) => e.name).toList());
    }));
    if (mounted) setState(() => _templates = templates);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _pick(_Template t) => setState(() {
        _ctrl.text = t.name;
        _selectedName = t.name;
      });

  List<String> get _selectedExercises =>
      _selectedName == null ? [] : (_templates.firstWhere((t) => t.name == _selectedName, orElse: () => (name: '', sessionId: 0, exercises: [])).exercises);

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final accent = Theme.of(context).colorScheme.primary;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final textMuted = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    final border = Theme.of(context).colorScheme.outline;
    final surface = Theme.of(context).inputDecorationTheme.fillColor ?? const Color(0xFF15181A);

    return AlertDialog(
      title: Text(lang.tr('dialog_program_title')),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _ctrl,
              autofocus: _templates.isEmpty,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: lang.tr('dialog_program_hint')),
              onSubmitted: (_) => Navigator.pop(context, (name: _ctrl.text, exercises: _selectedExercises)),
              onChanged: (_) {
                if (_selectedName != null) setState(() => _selectedName = null);
              },
            ),
            if (_templates.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                lang.tr('dialog_program_past'),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _templates.map((t) {
                      final selected = _selectedName == t.name;
                      return GestureDetector(
                        onTap: () => _pick(t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected ? accent.withValues(alpha: 0.1) : surface,
                            border: Border.all(color: selected ? accent : border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                t.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? accent : textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, (name: '', exercises: <String>[])),
          child: Text(lang.tr('btn_skip')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (name: _ctrl.text, exercises: _selectedExercises)),
          child: Text(lang.tr('btn_start')),
        ),
      ],
    );
  }
}

// ─── Volume Summary Row ───────────────────────────────────────────────────────

class _VolumeSummaryRow extends ConsumerWidget {
  final HomeState state;
  final bool isLbs;
  const _VolumeSummaryRow({required this.state, required this.isLbs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final accent = Theme.of(context).colorScheme.primary;
    final textMuted = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    final vol = _fmtVol(state.todayVolume, isLbs);
    final last = state.lastSessionVolume;
    final unit = isLbs ? 'lbs' : 'kg';

    String? changeStr;
    Color changeColor = textMuted;
    if (last > 0) {
      final pct = (state.todayVolume - last) / last * 100;
      final sign = pct >= 0 ? '+' : '';
      changeStr = '$sign${pct.toStringAsFixed(1)}%';
      changeColor = pct >= 0 ? accent : const Color(0xFFFF5A3C);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$vol total',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted),
            ),
            if (changeStr != null) ...[
              const SizedBox(width: 6),
              Text(
                changeStr,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: changeColor),
              ),
              Text(
                lang.tr('home_vs_prev'),
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
            ],
          ],
        ),
        if (state.bestE1RMToday > 0 && state.bestE1RMExercise != null) ...[
          const SizedBox(height: 3),
          Text(
            'Best e1RM: ${fmtNum(isLbs ? state.bestE1RMToday * kgToLbs : state.bestE1RMToday)} $unit  (${state.bestE1RMExercise})',
            style: TextStyle(fontSize: 11, color: textMuted),
          ),
        ],
      ],
    );
  }
}

// ─── Exercise List ────────────────────────────────────────────────────────────

class _ExerciseList extends ConsumerWidget {
  final HomeState state;
  final bool isLbs;
  const _ExerciseList({required this.state, required this.isLbs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final textMuted = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    final exercises = state.todayExercises;
    final hasWorkout = state.hasSessionToday || state.isFinishedToday;

    if (!hasWorkout) {
      return Center(
        child: Text(
          lang.tr('home_not_started'),
          style: TextStyle(fontSize: 13, color: textMuted),
        ),
      );
    }
    if (exercises.isEmpty) {
      return Center(
        child: Text(
          lang.tr('home_warming_up'),
          style: TextStyle(fontSize: 13, color: textMuted),
        ),
      );
    }

    final maxVolume = exercises.fold(0.0, (m, e) => e.totalVolume > m ? e.totalVolume : m);

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: exercises.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) {
        final ex = exercises[i];
        final w = isLbs ? ex.avgWeight * kgToLbs : ex.avgWeight;
        final vol = isLbs ? ex.totalVolume * kgToLbs : ex.totalVolume;
        final unit = isLbs ? 'lbs' : 'kg';
        final ratio = maxVolume > 0 ? ex.totalVolume / maxVolume : 0.0;

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          ex.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (ex.hasPrToday) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5A3C),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PR',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A0800),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ex.setCount} sets · ${fmtNum(w)} $unit',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PlateStack(ratio: ratio),
                const SizedBox(height: 4),
                Text(
                  '${fmtNum(vol)} $unit',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted),
                ),
                Text(
                  'vol.',
                  style: TextStyle(fontSize: 10, color: textMuted),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
