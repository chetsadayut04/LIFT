import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../core/database/session_dao.dart';
import '../../core/database/set_dao.dart';
import '../../core/providers/unit_provider.dart';
import 'stats_provider.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _showDaySheet(BuildContext context, String dateStr, bool isWorked) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DayDetailSheet(
        dateStr: dateStr,
        isWorked: isWorked,
        notifier: ref.read(statsProvider.notifier),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('สถิติ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(statsProvider.notifier).load(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _WeeklyCard(
                  workoutDates: state.workoutDates,
                  thisWeekSets: state.thisWeekSets,
                ),
                const SizedBox(height: 12),
                _CalendarCard(
                  workoutDates: state.workoutDates,
                  focusedMonth: _focusedMonth,
                  onMonthChanged: (m) => setState(() => _focusedMonth = m),
                  onDayTap: (dateStr, isWorked) =>
                      _showDaySheet(context, dateStr, isWorked),
                ),
                const SizedBox(height: 12),
                const _ExercisePrTable(),
              ],
            ),
    );
  }
}

// ─── Calendar ────────────────────────────────────────────────────────────────

class _CalendarCard extends StatelessWidget {
  final Set<String> workoutDates;
  final DateTime focusedMonth;
  final void Function(DateTime) onMonthChanged;
  final void Function(String dateStr, bool isWorked) onDayTap;

  const _CalendarCard({
    required this.workoutDates,
    required this.focusedMonth,
    required this.onMonthChanged,
    required this.onDayTap,
  });

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _showMonthPicker(BuildContext context) {
    showDialog<DateTime>(
      context: context,
      builder: (_) => _MonthPickerDialog(
        current: focusedMonth,
        maxMonth: DateTime(DateTime.now().year, DateTime.now().month),
      ),
    ).then((picked) {
      if (picked != null) onMonthChanged(picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF16A34A);
    final today = DateTime.now();
    final todayStr = _fmt(today);

    // Days in month
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateTime(
      focusedMonth.year,
      focusedMonth.month + 1,
      0,
    ).day;
    // weekday: 1=Mon ... 7=Sun, offset so Mon=col0
    final startOffset = (firstDay.weekday - 1) % 7;

    // Month/year label
    const thaiMonths = [
      '',
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];
    final monthLabel =
        '${thaiMonths[focusedMonth.month]} ${focusedMonth.year + 543}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                const Text(
                  'ปฏิทิน',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: Color(0xFF888888),
                  ),
                ),
                const Spacer(),
                _NavBtn(
                  icon: Icons.chevron_left,
                  onTap: () => onMonthChanged(
                    DateTime(focusedMonth.year, focusedMonth.month - 1),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _showMonthPicker(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        monthLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_drop_down,
                        size: 18,
                        color: Color(0xFF888888),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                _NavBtn(
                  icon: Icons.chevron_right,
                  onTap:
                      focusedMonth.year > today.year ||
                          focusedMonth.month >= today.month
                      ? null
                      : () => onMonthChanged(
                          DateTime(focusedMonth.year, focusedMonth.month + 1),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Day-of-week headers
            Row(
              children: const ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา']
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF888888),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),

            // Grid of days
            LayoutBuilder(
              builder: (context, constraints) {
                final cellSize = constraints.maxWidth / 7;
                const cellHeight = 36.0;
                final totalCells = startOffset + daysInMonth;
                final rows = (totalCells / 7).ceil();

                return Column(
                  children: List.generate(rows, (row) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: List.generate(7, (col) {
                          final cellIndex = row * 7 + col;
                          final day = cellIndex - startOffset + 1;

                          if (day < 1 || day > daysInMonth) {
                            return SizedBox(
                              width: cellSize,
                              height: cellHeight,
                            );
                          }

                          final date = DateTime(
                            focusedMonth.year,
                            focusedMonth.month,
                            day,
                          );
                          final dateStr = _fmt(date);
                          final isWorked = workoutDates.contains(dateStr);
                          final isToday = dateStr == todayStr;
                          final isFuture = date.isAfter(today);

                          return GestureDetector(
                            onTap: isFuture
                                ? null
                                : () => onDayTap(dateStr, isWorked),
                            child: SizedBox(
                              width: cellSize,
                              height: cellHeight,
                              child: Center(
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isWorked
                                        ? accent
                                        : isToday
                                        ? const Color(0xFFEAF5EA)
                                        : Colors.transparent,
                                    border: isToday && !isWorked
                                        ? Border.all(
                                            color: const Color(0xFF888888),
                                            width: 1,
                                          )
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$day',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isWorked
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                        color: isWorked
                                            ? Colors.white
                                            : isFuture
                                            ? const Color(0xFFBFDFBF)
                                            : const Color(0xFF888888),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                );
              },
            ),

            // Month summary + legend
            const SizedBox(height: 10),
            Row(
              children: [
                _LegendDot(color: accent, label: 'เล่นแล้ว'),
                const SizedBox(width: 16),
                const _LegendDot(
                  color: Color(0xFF888888),
                  label: 'ยังไม่ได้เล่น',
                ),
                const Spacer(),
                () {
                  final prefix =
                      '${focusedMonth.year}-${focusedMonth.month.toString().padLeft(2, '0')}';
                  final count = workoutDates
                      .where((d) => d.startsWith(prefix))
                      .length;
                  if (count == 0) return const SizedBox.shrink();
                  return Text(
                    'เดือนนี้ $count ครั้ง',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  );
                }(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _NavBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFFBFDFBF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null
              ? const Color(0xFFBFDFBF)
              : const Color(0xFF888888),
        ),
      ),
    );
  }
}

// ─── Month Picker Dialog ──────────────────────────────────────────────────────

class _MonthPickerDialog extends StatefulWidget {
  final DateTime current;
  final DateTime maxMonth;
  const _MonthPickerDialog({required this.current, required this.maxMonth});

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year;

  static const _thaiMonths = [
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ];

  @override
  void initState() {
    super.initState();
    _year = widget.current.year;
  }

  bool _isDisabled(int month) =>
      _year > widget.maxMonth.year ||
      (_year == widget.maxMonth.year && month > widget.maxMonth.month);

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF16A34A);
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _year--),
              ),
              Text(
                '${_year + 543}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _year >= widget.maxMonth.year
                    ? null
                    : () => setState(() => _year++),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(4, (row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: List.generate(3, (col) {
                  final i = row * 3 + col;
                  final month = i + 1;
                  final isCurrent =
                      _year == widget.current.year &&
                      month == widget.current.month;
                  final disabled = _isDisabled(month);
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: col > 0 ? 6 : 0),
                      child: GestureDetector(
                        onTap: disabled
                            ? null
                            : () => Navigator.pop(
                                context,
                                DateTime(_year, month),
                              ),
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? accent
                                : disabled
                                ? const Color(0xFFF0F0F0)
                                : const Color(0xFFEAF5EA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _thaiMonths[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isCurrent
                                  ? Colors.white
                                  : disabled
                                  ? const Color(0xFFBBBBBB)
                                  : accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Weekly Summary Card ──────────────────────────────────────────────────────

class _WeeklyCard extends StatelessWidget {
  final Set<String> workoutDates;
  final int thisWeekSets;

  const _WeeklyCard({
    required this.workoutDates,
    required this.thisWeekSets,
  });

  int _countSessions(DateTime monday) {
    int count = 0;
    for (var i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      final s =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      if (workoutDates.contains(s)) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF111111);
    const textMuted = Color(0xFF888888);

    final now = DateTime.now();
    final thisMonday = now.subtract(Duration(days: now.weekday - 1));

    final thisSessions = _countSessions(thisMonday);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'สัปดาห์นี้',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Sessions
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$thisSessions',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'ครั้ง',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ],
                  ),
                ),
                // Divider
                Container(width: 1, height: 56, color: const Color(0xFFE0E0E0)),
                const SizedBox(width: 16),
                // Sets
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$thisWeekSets',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'sets',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Exercise PR Table ────────────────────────────────────────────────────────

class _ExercisePrTable extends ConsumerStatefulWidget {
  const _ExercisePrTable();

  @override
  ConsumerState<_ExercisePrTable> createState() => _ExercisePrTableState();
}

class _ExercisePrTableState extends ConsumerState<_ExercisePrTable> {
  List<String> _programs = [];
  String? _selectedProgram; // null = ทั้งหมด
  List<({String name, double prKg, int prReps, int totalSets})> _prs = [];
  bool _loading = true;
  final _setDao = SetDao();
  final _sessionDao = SessionDao();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final sessions = await _sessionDao.getRecentNamedSessions(limit: 20);
    final seen = <String>{};
    final programs = <String>[];
    for (final s in sessions) {
      if (seen.add(s.name!)) programs.add(s.name!);
    }
    if (mounted) setState(() => _programs = programs);
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = _selectedProgram == null
        ? await _setDao.getAllExercisePrs()
        : await _setDao.getExerciseStatsBySessionName(_selectedProgram!);
    if (mounted) {
      setState(() {
        _prs = result;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF111111);
    const textMuted = Color(0xFF888888);
    const accent = Color(0xFF16A34A);

    final isLbs = ref.watch(isLbsProvider);
    final unit = isLbs ? 'lbs' : 'kg';

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'สถิติ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: textMuted,
                  ),
                ),
                const Spacer(),
                if (_programs.isNotEmpty)
                  PopupMenuButton<String?>(
                    onSelected: (val) {
                      setState(() => _selectedProgram = val);
                      _load();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem<String?>(
                        value: null,
                        child: Text('ทั้งหมด'),
                      ),
                      ..._programs.map(
                        (name) => PopupMenuItem<String?>(
                          value: name,
                          child: Text(name),
                        ),
                      ),
                    ],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedProgram ?? 'ทั้งหมด',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          size: 18,
                          color: Color(0xFF888888),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_prs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'ยังไม่มีข้อมูล',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 13),
                ),
              )
            else ...[
              Row(
                children: [
                  const Expanded(
                    flex: 5,
                    child: Text(
                      'ท่า',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Tooltip(
                      message: 'น้ำหนักสูงสุดที่ประเมินว่ายกได้ 1 ครั้ง\nสูตร Epley: น้ำหนัก × (1 + reps/30)',
                      triggerMode: TooltipTriggerMode.tap,
                      showDuration: const Duration(seconds: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Text(
                            'e1RM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF888888),
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.info_outline, size: 10, color: Color(0xFF888888)),
                        ],
                      ),
                    ),
                  ),
                  const Expanded(
                    flex: 3,
                    child: Text(
                      'Best set',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                      ),
                    ),
                  ),
                  const Expanded(
                    flex: 2,
                    child: Text(
                      'sets',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Divider(height: 1),
              ...() {
                final maxE1RM = _prs.map((p) => calc1RM(p.prKg, p.prReps)).reduce(math.max);
                return _prs.map((p) {
                  final e1rm = calc1RM(p.prKg, p.prReps);
                  final e1rmDisplay = isLbs ? e1rm * kgToLbs : e1rm;
                  final bestW = isLbs ? p.prKg * kgToLbs : p.prKg;
                  final ratio = maxE1RM > 0 ? e1rm / maxE1RM : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                p.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                '${fmtNum(e1rmDisplay)} $unit',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                '${fmtNum(bestW)}×${p.prReps}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: textMuted,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${p.totalSets}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 3,
                            backgroundColor: const Color(0xFFF0F0F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              accent.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList();
              }(),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Legend Dot ──────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}

// ─── Exercise Chart ───────────────────────────────────────────────────────────

/// Returns a "nice" interval for the Y-axis so that there are roughly
/// [targetTicks] evenly-spaced labels between 0 and [maxVal].
/// Rounds to clean steps like 1, 2, 5, 10, 25, 50, 100, 250, 500, 1000 …
double _niceInterval(double maxVal, {int targetTicks = 5}) {
  if (maxVal <= 0) return 20;
  final rawStep = maxVal / targetTicks;
  // Find the magnitude (power of 10) just below rawStep
  double mag = 1;
  while (mag * 10 <= rawStep) {
    mag *= 10;
  }
  // Choose the nicest multiple of that magnitude
  const candidates = [1.0, 2.0, 2.5, 5.0, 10.0];
  double step = mag * 10;
  for (final c in candidates) {
    final s = c * mag;
    if (s >= rawStep) {
      step = s;
      break;
    }
  }
  return step == 0 ? 1 : step;
}

class _ExerciseChart extends ConsumerStatefulWidget {
  final String exerciseName;
  final List<({String dateStr, double volume})> history;
  final List<({String dateStr, double maxWeight})> maxWeightHistory;

  const _ExerciseChart({
    required this.exerciseName,
    required this.history,
    required this.maxWeightHistory,
  });

  @override
  ConsumerState<_ExerciseChart> createState() => _ExerciseChartState();
}

class _ExerciseChartState extends ConsumerState<_ExerciseChart> {
  bool _showMaxWeight = false;

  @override
  Widget build(BuildContext context) {
    final isLbs = ref.watch(isLbsProvider);
    final unit = isLbs ? 'lbs' : 'kg';
    const accent = Color(0xFF16A34A);

    final displayData = _showMaxWeight
        ? widget.maxWeightHistory
              .map(
                (e) => (
                  dateStr: e.dateStr,
                  value: isLbs ? e.maxWeight * kgToLbs : e.maxWeight,
                ),
              )
              .toList()
        : widget.history
              .map(
                (e) => (
                  dateStr: e.dateStr,
                  value: isLbs ? e.volume * kgToLbs : e.volume,
                ),
              )
              .toList();

    final maxY = displayData.fold(0.0, (m, e) => e.value > m ? e.value : m);
    final chartMaxY = maxY == 0 ? 100.0 : maxY * 1.2;
    final interval = _niceInterval(chartMaxY);

    final barGroups = displayData.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.value,
            color: accent,
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.exerciseName.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: Color(0xFF888888),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _showMaxWeight
                        ? 'น้ำหนักสูงสุด ย้อนหลัง ($unit)'
                        : 'Volume รายวัน ย้อนหลัง ($unit)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showMaxWeight = !_showMaxWeight),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5EA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBFDFBF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Vol',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _showMaxWeight
                                ? const Color(0xFF3A3845)
                                : const Color(0xFF111111),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            '|',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF3A3845),
                            ),
                          ),
                        ),
                        Text(
                          'Max',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _showMaxWeight
                                ? const Color(0xFF111111)
                                : const Color(0xFF3A3845),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: chartMaxY,
                  barGroups: barGroups,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: Color(0xFFBFDFBF), strokeWidth: 1),
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: interval,
                        getTitlesWidget: (val, _) {
                          if (val % interval != 0 && val != 0) {
                            return const SizedBox.shrink();
                          }
                          final display = val >= 1000
                              ? '${fmtNum(val / 1000)}k'
                              : fmtNum(val);
                          return Text(
                            display,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF888888),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, _) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= displayData.length) {
                            return const SizedBox.shrink();
                          }
                          final parts = displayData[idx].dateStr.split('-');
                          final label = parts.length == 3
                              ? '${int.parse(parts[2])}/${int.parse(parts[1])}'
                              : displayData[idx].dateStr;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF888888),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Day Detail Bottom Sheet ──────────────────────────────────────────────────

class _DayDetailSheet extends ConsumerStatefulWidget {
  final String dateStr;
  final bool isWorked;
  final StatsNotifier notifier;

  const _DayDetailSheet({
    required this.dateStr,
    required this.isWorked,
    required this.notifier,
  });

  @override
  ConsumerState<_DayDetailSheet> createState() => _DayDetailSheetState();
}

class _DayDetailSheetState extends ConsumerState<_DayDetailSheet> {
  List<({String name, List<({int reps, double weightKg})> sets})>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.notifier.getDayDetail(widget.dateStr).then((data) {
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    });
  }

  String _formatDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    const thaiMonths = [
      '',
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    final month = int.tryParse(parts[1]) ?? 0;
    return '${parts[2]} ${thaiMonths[month]} ${int.parse(parts[0]) + 543}';
  }

  @override
  Widget build(BuildContext context) {
    final isLbs = ref.watch(isLbsProvider);
    final unit = isLbs ? 'lbs' : 'kg';
    const accent = Color(0xFF16A34A);
    final dateLabel = _formatDate(widget.dateStr);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF4FAF4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Color(0xFFBFDFBF), width: 0.5)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFBFDFBF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isWorked ? accent : const Color(0xFF888888),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (!widget.isWorked || (_data != null && _data!.isEmpty))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.hotel_outlined,
                    size: 18,
                    color: Color(0xFF888888),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'วันพักผ่อน',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _data!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final ex = _data![i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...ex.sets.asMap().entries.map((e) {
                        final s = e.value;
                        final w = isLbs ? s.weightKg * kgToLbs : s.weightKg;
                        final wStr = '${fmtNum(w)} $unit';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '${e.key + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF888888),
                                  ),
                                ),
                              ),
                              Text(
                                '$wStr × ${s.reps} reps',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF888888),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
