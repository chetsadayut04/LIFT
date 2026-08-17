import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/database/exercise_dao.dart';
import '../../core/database/session_dao.dart';
import '../../core/providers/unit_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/translation_provider.dart';
import '../workout/active_workout_provider.dart';
import '../workout/active_workout_screen.dart';
import '../workout/routine_provider.dart';
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

    final hasWorkout = state.hasSessionToday;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top bar ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LIFT',
                style: GoogleFonts.barlowCondensed(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                  color: accent,
                  height: 1.0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  dateText,
                  style: GoogleFonts.sarabun(
                    fontSize: 12,
                    color: textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Weekly Consistency ────────────────────────────────────
          _ConsistencyCalendar(finishedDates: state.finishedDates),
          const SizedBox(height: 24),

          // ── Main Body (Conditional) ──────────────────────────────
          Expanded(
            child: hasWorkout
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Session Name & Timer row matching Figma
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang == AppLanguage.th ? 'กำลังฝึกซ้อม' : 'WORKOUT IN PROGRESS',
                                  style: GoogleFonts.sarabun(
                                    fontSize: 12,
                                    color: textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  state.sessionName ?? lang.tr('home_ready'),
                                  style: GoogleFonts.barlowCondensed(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    height: 1.1,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                lang == AppLanguage.th ? 'เวลาที่ใช้' : 'TIME ELAPSED',
                                style: GoogleFonts.sarabun(
                                  fontSize: 11,
                                  color: textMuted,
                                ),
                              ),
                              const SizedBox(height: 3),
                              _TimerRow(state: state, fontSize: 28, hideDot: true),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Pulsing progress bar matching Figma CSS
                      _PulsingWorkoutProgress(state: state),
                      if (state.todayVolume > 0) ...[
                        const SizedBox(height: 10),
                        _VolumeSummaryRow(state: state, isLbs: isLbs),
                      ],
                      const SizedBox(height: 16),
                      Divider(height: 1, thickness: 0.5, color: divider),
                      const SizedBox(height: 16),
                      Text(
                        lang.tr('home_today'),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Active/Completed Exercise List
                      Expanded(
                        child: _ExerciseList(state: state, isLbs: isLbs),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Large Title
                        Text(
                          lang.tr('home_ready'),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Stats Summary Dashboard
                        _StatsSummaryDashboard(state: state, isLbs: isLbs),
                        const SizedBox(height: 24),
                        // Routines Carousel header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              lang == AppLanguage.th ? 'ตารางฝึกของฉัน' : 'MY ROUTINES',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Routines Carousel
                        const _RoutinesCarousel(),
                      ],
                    ),
                  ),
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
          // Finish Workout
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () => _finish(context, ref, lang, accent),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  lang == AppLanguage.th ? 'เสร็จสิ้นการฝึก' : 'Finish',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Continue Workout
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () => _continue(context, ref),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      lang == AppLanguage.th ? 'บันทึกต่อ' : 'Continue',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
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
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow, size: 18),
            const SizedBox(width: 4),
            Text(
              lang == AppLanguage.th ? 'เริ่มการฝึก' : 'Start Workout',
              style: GoogleFonts.barlowCondensed(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
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
    try {
      await ref.read(homeProvider.notifier).reopenSession();
      await ref.read(activeWorkoutProvider.notifier).loadTodaySession();
      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
      );
      ref.read(homeProvider.notifier).load();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reopening workout: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
      try {
        ref.read(activeWorkoutProvider.notifier).clearSession();
        await ref.read(homeProvider.notifier).finishSession();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error finishing workout: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
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
  final double? fontSize;
  final bool hideDot;
  const _TimerRow({required this.state, this.fontSize, this.hideDot = false});

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
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.hideDot) ...[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? accent : textMuted,
            ),
          ),
          const SizedBox(width: 10),
        ],
        Text(
          timerStr,
          style: GoogleFonts.jetBrainsMono(
            fontSize: widget.fontSize ?? 22,
            fontWeight: FontWeight.w600,
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
          state.isFinishedToday
              ? (lang == AppLanguage.th ? 'เสร็จสิ้น' : 'Finished')
              : lang.tr('home_warming_up'),
          style: TextStyle(fontSize: 13, color: textMuted),
        ),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: exercises.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final ex = exercises[i];
        final w = isLbs ? ex.avgWeight * kgToLbs : ex.avgWeight;
        final unit = isLbs ? 'lbs' : 'kg';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1F1B).withValues(alpha: 0.65) : const Color(0xFFF1F5F0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.07),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.name,
                      style: GoogleFonts.sarabun(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${fmtNum(w)} $unit',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: textMuted,
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
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${ex.setCount}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                  Text(
                    lang == AppLanguage.th ? 'เซ็ต' : 'sets',
                    style: GoogleFonts.sarabun(
                      fontSize: 11,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Consistency Calendar Widget ──────────────────────────────────────────

class _ConsistencyCalendar extends ConsumerWidget {
  final Set<String> finishedDates;
  const _ConsistencyCalendar({required this.finishedDates});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final textMuted = theme.textTheme.bodySmall?.color ?? Colors.grey;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.white;

    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));

    final thaiShortDays = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
    final enShortDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang == AppLanguage.th ? 'ความสม่ำเสมอสัปดาห์นี้' : 'WEEKLY CONSISTENCY',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final day = weekDays[index];
            final dayLabel = lang == AppLanguage.th ? thaiShortDays[index] : enShortDays[index];
            final dateStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
            final isCompleted = finishedDates.contains(dateStr);
            final isToday = day.day == now.day && day.month == now.month && day.year == now.year;

            return Column(
              children: [
                Text(
                  dayLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isToday ? accent : textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? accent.withValues(alpha: 0.15)
                        : (isToday ? theme.colorScheme.outline.withValues(alpha: 0.1) : Colors.transparent),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted
                          ? accent
                          : (isToday ? accent.withValues(alpha: 0.5) : theme.colorScheme.outline.withValues(alpha: 0.5)),
                      width: isCompleted || isToday ? 1.5 : 1,
                    ),
                    boxShadow: isCompleted
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.3),
                              blurRadius: 6,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: isCompleted
                      ? Icon(Icons.check, size: 14, color: accent)
                      : Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday ? accent : textPrimary,
                          ),
                        ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

// ─── Stats Summary Dashboard Widget ──────────────────────────────────────────

class _StatsSummaryDashboard extends ConsumerStatefulWidget {
  final HomeState state;
  final bool isLbs;
  const _StatsSummaryDashboard({required this.state, required this.isLbs});

  @override
  ConsumerState<_StatsSummaryDashboard> createState() => _StatsSummaryDashboardState();
}

class _StatsSummaryDashboardState extends ConsumerState<_StatsSummaryDashboard> {
  int _targetGoal = 12;

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _targetGoal = prefs.getInt('monthly_workout_goal') ?? 12;
      });
    }
  }

  Future<void> _saveGoal(int newGoal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('monthly_workout_goal', newGoal);
    if (mounted) {
      setState(() {
        _targetGoal = newGoal;
      });
    }
  }

  Future<void> _showSetGoalDialog(BuildContext context, AppLanguage lang) async {
    final controller = TextEditingController(text: _targetGoal.toString());
    int selected = _targetGoal;

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF16221B),
            title: Row(
              children: [
                const Icon(Icons.flag_rounded, color: Color(0xFF10B981), size: 22),
                const SizedBox(width: 8),
                Text(
                  lang == AppLanguage.th ? 'กำหนดเป้าหมายรายเดือน' : 'Set Monthly Goal',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang == AppLanguage.th
                      ? 'เลือกจำนวนวันที่ตั้งใจจะฝึกซ้อมในแต่ละเดือน:'
                      : 'Select target workout days per month:',
                  style: GoogleFonts.sarabun(
                    fontSize: 13,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [8, 12, 16, 20, 24].map((days) {
                    final isSelected = selected == days;
                    return ChoiceChip(
                      label: Text(
                        '$days ${lang == AppLanguage.th ? 'วัน' : 'days'}',
                        style: GoogleFonts.sarabun(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.black : const Color(0xFFE2E8F0),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF10B981),
                      backgroundColor: const Color(0xFF223326),
                      onSelected: (val) {
                        if (val) {
                          setDialogState(() {
                            selected = days;
                            controller.text = days.toString();
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: lang == AppLanguage.th ? 'ระบุจำนวนวันเอง' : 'Custom Target Days',
                    labelStyle: GoogleFonts.sarabun(color: const Color(0xFF94A3B8), fontSize: 12),
                    suffixText: lang == AppLanguage.th ? 'วัน' : 'days',
                    suffixStyle: GoogleFonts.sarabun(color: const Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFF0A0E0B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF223326)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF10B981)),
                    ),
                  ),
                  onChanged: (val) {
                    final parsed = int.tryParse(val);
                    if (parsed != null && parsed > 0 && parsed <= 31) {
                      setDialogState(() {
                        selected = parsed;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  lang == AppLanguage.th ? 'ยกเลิก' : 'Cancel',
                  style: GoogleFonts.sarabun(color: const Color(0xFF94A3B8)),
                ),
              ),
              FilledButton(
                onPressed: () {
                  final customVal = int.tryParse(controller.text.trim());
                  final finalGoal = (customVal != null && customVal > 0 && customVal <= 31)
                      ? customVal
                      : selected;
                  Navigator.pop(ctx, finalGoal);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.black,
                ),
                child: Text(
                  lang == AppLanguage.th ? 'บันทึก' : 'Save',
                  style: GoogleFonts.sarabun(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (result != null && result > 0) {
      _saveGoal(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final textMuted = theme.textTheme.bodySmall?.color ?? Colors.grey;
    final border = theme.colorScheme.outline;

    // Monthly Workout calculations
    final now = DateTime.now();
    final currentMonthPrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}-';
    final workoutsThisMonth = widget.state.finishedDates.where((d) => d.startsWith(currentMonthPrefix)).length;
    final progressRatio = _targetGoal > 0 ? (workoutsThisMonth / _targetGoal).clamp(0.0, 1.0) : 0.0;

    // Weekly Volume
    final weeklyVol = _fmtVol(widget.state.thisWeekVolume, widget.isLbs);
    final changeText = widget.state.percentChange != null
        ? '${widget.state.percentChange! >= 0 ? '+' : ''}${widget.state.percentChange!.toStringAsFixed(1)}%'
        : null;
    final changeColor = widget.state.percentChange != null && widget.state.percentChange! >= 0
        ? accent
        : const Color(0xFFFF5A3C);

    // Calculate maximum daily volume for mini bar chart
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekDates = List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    });
    final maxDailyVolume = weekDates.map((d) => widget.state.weeklyVolumePerDay[d] ?? 0.0).fold(0.0, math.max);

    return Row(
      children: [
        // Left Card: Weekly Volume Summary
        Expanded(
          child: Container(
            height: 130,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E211F) : const Color(0xFFF1F5F0),
              border: Border.all(color: border, width: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang == AppLanguage.th ? 'น้ำหนักสัปดาห์นี้' : 'WEEKLY VOLUME',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 0.5),
                ),
                const Spacer(),
                Text(
                  weeklyVol,
                  style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 2),
                if (changeText != null)
                  Text(
                    lang == AppLanguage.th ? '$changeText จากสัปดาห์ก่อน' : '$changeText vs last week',
                    style: TextStyle(fontSize: 10, color: changeColor, fontWeight: FontWeight.w600),
                  )
                else
                  Text(
                    lang == AppLanguage.th ? 'ไม่มีข้อมูลสัปดาห์ก่อน' : 'No previous week data',
                    style: TextStyle(fontSize: 10, color: textMuted),
                  ),
                const Spacer(),
                // Mini bar chart
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final dayVol = widget.state.weeklyVolumePerDay[weekDates[i]] ?? 0.0;
                    final ratio = maxDailyVolume > 0 ? dayVol / maxDailyVolume : 0.0;
                    final barHeight = 14 * ratio + 3.0; // min height 3px

                    return Container(
                      width: 6,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: dayVol > 0 ? accent : theme.colorScheme.outline.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Right Card: Monthly Workouts Target Progress Ring
        Expanded(
          child: InkWell(
            onTap: () => _showSetGoalDialog(context, lang),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 130,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E211F) : const Color(0xFFF1F5F0),
                border: Border.all(color: border, width: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          lang == AppLanguage.th ? 'เป้าหมายรายเดือน' : 'MONTHLY GOAL',
                          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 0.3),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: accent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_outlined, size: 10, color: accent),
                            const SizedBox(width: 2),
                            Text(
                              lang == AppLanguage.th ? 'ตั้งเป้า' : 'Edit',
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: accent),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              lang == AppLanguage.th ? 'ฝึกซ้อมครบ' : 'Completed',
                              style: TextStyle(fontSize: 10, color: textMuted),
                            ),
                            Text(
                              lang == AppLanguage.th ? '$workoutsThisMonth วัน' : '$workoutsThisMonth days',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 2),
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: progressRatio,
                              strokeWidth: 4.5,
                              backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(accent),
                            ),
                            Text(
                              '$workoutsThisMonth/$_targetGoal',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Routines Carousel Widget ──────────────────────────────────────────

class _RoutinesCarousel extends ConsumerWidget {
  const _RoutinesCarousel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final theme = Theme.of(context);
    final routineState = ref.watch(routineProvider);
    final textMuted = theme.textTheme.bodySmall?.color ?? Colors.grey;
    final textPrimary = theme.textTheme.bodyLarge?.color ?? Colors.white;

    final gradientList = const [
      LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF4F46E5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEF4444)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      LinearGradient(colors: [Color(0xFF10B981), Color(0xFF0D9488)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ];

    if (routineState.routines.isEmpty) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark ? const Color(0xFF1E211F) : const Color(0xFFF1F5F0),
          border: Border.all(color: theme.colorScheme.outline, width: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              lang == AppLanguage.th ? 'สร้างตารางฝึกซ้อมของคุณ' : 'Create Workout Routines',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              lang == AppLanguage.th 
                  ? 'สร้างตารางฝึกได้ง่ายๆ ที่เมนู โปรไฟล์ > ตารางฝึกของฉัน'
                  : 'Go to Profile > My Routines to build your workout plans.',
              style: TextStyle(fontSize: 11, color: textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 155,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: routineState.routines.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final item = routineState.routines[i];
          final routine = item.routine;
          final exercises = item.exercises;
          final gradient = gradientList[i % gradientList.length];

          return Container(
            width: 220,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.last.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lang == AppLanguage.th ? '${exercises.length} ท่า' : '${exercises.length} Exs',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        final exNames = exercises.map((e) => e.exercise.name).toList();
                        await ref.read(activeWorkoutProvider.notifier).startSessionFromTemplate(
                              routine.name,
                              exNames,
                            );
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
                          );
                          ref.read(homeProvider.notifier).load();
                        }
                      },
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  routine.name,
                  style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  exercises.map((e) => e.exercise.name).join(', '),
                  style: const TextStyle(fontSize: 10, color: Colors.white70, fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}



// ─── Pulsing Workout Progress Indicator Widget ────────────────────────────────

class _PulsingWorkoutProgress extends StatefulWidget {
  final HomeState state;
  const _PulsingWorkoutProgress({required this.state});

  @override
  State<_PulsingWorkoutProgress> createState() => _PulsingWorkoutProgressState();
}

class _PulsingWorkoutProgressState extends State<_PulsingWorkoutProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      height: 3,
      width: double.infinity,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FadeTransition(
        opacity: _animation,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: 0.6, // Matching figma (60% width)
          child: Container(
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
