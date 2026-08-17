import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../core/database/session_dao.dart';
import '../../core/providers/unit_provider.dart';
import '../../core/providers/translation_provider.dart';
import '../history/history_screen.dart';
import 'stats_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: StatsSection(),
        ),
      ),
    );
  }
}

class StatsSection extends ConsumerStatefulWidget {
  const StatsSection({super.key});

  @override
  ConsumerState<StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends ConsumerState<StatsSection> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String _selectedPeriod = '3M';
  String? _currentExercise;

  static const _defaultExercises = [
    'Bench Press',
    'Back Squat',
    'Deadlift',
    'Overhead Press',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initExerciseSelection();
    });
  }

  void _initExerciseSelection() {
    final state = ref.read(statsProvider);
    final available = state.exerciseNames.isNotEmpty
        ? state.exerciseNames
        : _defaultExercises;
    if (_currentExercise == null && available.isNotEmpty) {
      final initial = available.first;
      setState(() => _currentExercise = initial);
      ref.read(statsProvider.notifier).selectExercise(initial);
    }
  }

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

  List<({String dateStr, double maxWeight})> _getFilteredHistory(
    List<({String dateStr, double maxWeight})> raw,
  ) {
    if (raw.isEmpty) return [];
    if (_selectedPeriod == 'ALL') return raw;

    final now = DateTime.now();
    late DateTime cutoff;
    if (_selectedPeriod == '1M') {
      cutoff = DateTime(now.year, now.month - 1, now.day);
    } else if (_selectedPeriod == '3M') {
      cutoff = DateTime(now.year, now.month - 3, now.day);
    } else if (_selectedPeriod == '6M') {
      cutoff = DateTime(now.year, now.month - 6, now.day);
    } else {
      return raw;
    }

    return raw.where((e) {
      final parsed = DateTime.tryParse(e.dateStr);
      if (parsed != null) {
        return parsed.isAfter(cutoff) || parsed.isAtSameMomentAs(cutoff);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statsProvider);
    final lang = ref.watch(languageProvider);
    final isLbs = ref.watch(isLbsProvider);
    final unit = isLbs ? 'lbs' : 'kg';

    final hasExercises = state.exerciseNames.isNotEmpty;
    final exercises = hasExercises ? state.exerciseNames : <String>[];
    final selectedEx = hasExercises ? (_currentExercise ?? exercises.first) : '';
    final history = hasExercises ? _getFilteredHistory(state.maxWeightHistory) : <({String dateStr, double maxWeight})>[];

    final maxVal = history.isNotEmpty
        ? history.fold<double>(
            0.0,
            (max, e) => e.maxWeight > max ? e.maxWeight : max,
          )
        : 0.0;
    final displayMaxVal = isLbs ? maxVal * kgToLbs : maxVal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header Title & Period Filter ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang == AppLanguage.th ? 'สถิติ & วิเคราะห์' : 'Stats & Analytics',
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFFFFFFF),
                      letterSpacing: -0.5,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HistoryScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.history_rounded, size: 16, color: Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Text(
                            lang == AppLanguage.th ? 'ประวัติ' : 'History',
                            style: GoogleFonts.sarabun(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Period Filter Tabs (1M, 3M, 6M, ALL)
              Row(
                children: ['1M', '3M', '6M', 'ALL'].map((p) {
                  final isSelected = _selectedPeriod == p;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPeriod = p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF10B981)
                                : const Color(0xFF1A241E),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            p,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? const Color(0xFF000000)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // ── Exercises & PR Section ──────────────────────────────────────────
        if (!hasExercises)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF121A15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF223326),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.fitness_center_outlined,
                  size: 44,
                  color: const Color(0xFF94A3B8).withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  lang == AppLanguage.th
                      ? 'ยังไม่มีข้อมูลท่าออกกำลังกาย'
                      : 'No Exercises Recorded Yet',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lang == AppLanguage.th
                      ? 'เมื่อเริ่มเพิ่มท่าและบันทึกเซสชันการฝึกซ้อม กราฟแนวโน้ม PR และสถิติส่วนตัวจะปรากฏขึ้นที่นี่'
                      : 'Add exercises and record workout sessions to see PR trend charts and personal records here.',
                  style: GoogleFonts.sarabun(
                    fontSize: 13,
                    color: const Color(0xFF94A3B8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else ...[
          // ── Exercise Chips Horizontal Selector ──────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang == AppLanguage.th ? 'ท่าออกกำลังกาย' : 'EXERCISES',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: exercises.map((ex) {
                      final isSelected = ex == selectedEx;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _currentExercise = ex);
                            ref.read(statsProvider.notifier).selectExercise(ex);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                  : const Color(0xFF1A241E),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF10B981).withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Text(
                              ex,
                              style: GoogleFonts.sarabun(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── PR Trend Line Chart Card ─────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF121A15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF223326),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PR TREND',
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF94A3B8),
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          selectedEx,
                          style: GoogleFonts.sarabun(
                            fontSize: 13,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          fmtNum(displayMaxVal),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        Text(
                          lang == AppLanguage.th
                              ? 'สูงสุด ($unit)'
                              : 'MAX ($unit)',
                          style: GoogleFonts.sarabun(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Line Chart
                SizedBox(
                  height: 160,
                  child: _buildPrLineChart(history, isLbs, lang, selectedEx),
                ),
              ],
            ),
          ),

          // ── Personal PR Records Section ("สถิติส่วนตัว (PR)") ─────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              lang == AppLanguage.th ? 'สถิติส่วนตัว (PR)' : 'PERSONAL RECORDS',
              style: GoogleFonts.barlowCondensed(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF94A3B8),
                letterSpacing: 0.8,
              ),
            ),
          ),

          _buildPersonalPrList(state.exercisePrs, selectedEx, lang, isLbs),
        ],

        const SizedBox(height: 24),

        // ── Expandable Calendar Card ───────────────────────────────────────
        _CalendarCard(
          workoutDates: state.workoutDates,
          focusedMonth: _focusedMonth,
          onMonthChanged: (m) => setState(() => _focusedMonth = m),
          onDayTap: (dateStr, isWorked) =>
              _showDaySheet(context, dateStr, isWorked),
          lang: lang,
        ),
      ],
    );
  }

  Widget _buildPrLineChart(
    List<({String dateStr, double maxWeight})> history,
    bool isLbs,
    AppLanguage lang,
    String exerciseName,
  ) {
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insert_chart_outlined_rounded,
                size: 32,
                color: const Color(0xFF94A3B8).withValues(alpha: 0.4),
              ),
              const SizedBox(height: 8),
              Text(
                lang == AppLanguage.th
                    ? 'ยังไม่มีบันทึกเซตสำหรับท่า "$exerciseName"'
                    : 'No workout sets recorded for "$exerciseName" yet',
                style: GoogleFonts.sarabun(
                  color: const Color(0xFFFFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                lang == AppLanguage.th
                    ? 'เริ่มเล่นและบันทึกเซต (น้ำหนัก / จำนวนครั้ง) ในหน้า Workout เพื่อดูพัฒนาการ'
                    : 'Log weight and reps in the Workout tab to see progress chart',
                style: GoogleFonts.sarabun(
                  color: const Color(0xFF94A3B8),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final spots = history.asMap().entries.map((e) {
      final w = isLbs ? e.value.maxWeight * kgToLbs : e.value.maxWeight;
      return FlSpot(e.key.toDouble(), w);
    }).toList();

    final minY = history
        .map((e) => isLbs ? e.maxWeight * kgToLbs : e.maxWeight)
        .reduce((a, b) => a < b ? a : b);
    final maxY = history
        .map((e) => isLbs ? e.maxWeight * kgToLbs : e.maxWeight)
        .reduce((a, b) => a > b ? a : b);

    final chartMin = (minY * 0.95).floorToDouble();
    final chartMax = (maxY * 1.05).ceilToDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ((chartMax - chartMin) / 3).clamp(1.0, 1000.0),
          getDrawingHorizontalLine: (_) => const FlLine(
            color: Color(0x1AFFFFFF),
            strokeWidth: 1,
            dashArray: [3, 3],
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (val, _) => Text(
                '${val.toInt()}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) {
                final idx = val.toInt();
                if (idx >= 0 && idx < history.length) {
                  final date = history[idx].dateStr;
                  final parts = date.split('-');
                  final label = parts.length == 3
                      ? '${int.parse(parts[2])}/${int.parse(parts[1])}'
                      : date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
                      style: GoogleFonts.sarabun(
                        fontSize: 10,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (history.length - 1).toDouble().clamp(0, double.infinity),
        minY: chartMin,
        maxY: chartMax == chartMin ? chartMin + 10 : chartMax,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF10B981),
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 3.5,
                color: const Color(0xFF10B981),
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF10B981).withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalPrList(
    List<({String name, double prKg, int prReps, int totalSets})> prs,
    String selectedEx,
    AppLanguage lang,
    bool isLbs,
  ) {
    final unit = isLbs ? 'lbs' : 'kg';
    if (prs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF121A15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF223326)),
        ),
        alignment: Alignment.center,
        child: Text(
          lang == AppLanguage.th
              ? 'ยังไม่มีสถิติส่วนตัว (PR)'
              : 'No Personal Records Yet',
          style: GoogleFonts.sarabun(
            fontSize: 13,
            color: const Color(0xFF94A3B8),
          ),
        ),
      );
    }

    final displayPrs = List<({String name, double prKg, int prReps, int totalSets})>.from(prs);
    displayPrs.sort((a, b) {
      if (a.name == selectedEx) return -1;
      if (b.name == selectedEx) return 1;
      return b.prKg.compareTo(a.prKg);
    });

    final maxPr = displayPrs.map((e) => e.prKg).reduce(math.max);

    return Column(
      children: displayPrs.asMap().entries.map((entry) {
        final i = entry.key;
        final pr = entry.value;
        final isSelected = pr.name == selectedEx;
        final displayW = isLbs ? pr.prKg * kgToLbs : pr.prKg;
        final pct = maxPr > 0 ? (pr.prKg / maxPr) * 100 : 100.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF10B981).withValues(alpha: 0.08)
                : const Color(0xFF121A15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF10B981).withValues(alpha: 0.6)
                  : const Color(0xFF223326),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#${i + 1} ',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          Text(
                            pr.name,
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFFFFFF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lang == AppLanguage.th
                            ? '${pr.totalSets} เซ็ตทั้งหมด'
                            : '${pr.totalSets} total sets',
                        style: GoogleFonts.sarabun(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: fmtNum(displayW),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            TextSpan(
                              text: ' $unit',
                              style: GoogleFonts.sarabun(
                                fontSize: 11,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '× ${pr.prReps} reps',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Gradient progress bar
              Stack(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: (pct / 100).clamp(0.0, 1.0),
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Calendar ────────────────────────────────────────────────────────────────

class _CalendarCard extends StatelessWidget {
  final Set<String> workoutDates;
  final DateTime focusedMonth;
  final void Function(DateTime) onMonthChanged;
  final void Function(String dateStr, bool isWorked) onDayTap;
  final AppLanguage lang;

  const _CalendarCard({
    required this.workoutDates,
    required this.focusedMonth,
    required this.onMonthChanged,
    required this.onDayTap,
    required this.lang,
  });

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _showMonthPicker(BuildContext context) {
    showDialog<DateTime>(
      context: context,
      builder: (_) => _MonthPickerDialog(
        current: focusedMonth,
        maxMonth: DateTime(DateTime.now().year, DateTime.now().month),
        lang: lang,
      ),
    ).then((picked) {
      if (picked != null) onMonthChanged(picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
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
      '', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
    ];
    const enMonths = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final monthName = lang == AppLanguage.th ? thaiMonths[focusedMonth.month] : enMonths[focusedMonth.month];
    final yearStr = lang == AppLanguage.th ? '${focusedMonth.year + 543}' : '${focusedMonth.year}';
    final monthLabel = '$monthName $yearStr';

    final dayHeaders = lang == AppLanguage.th 
        ? const ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา']
        : const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Text(
                  lang == AppLanguage.th ? 'ปฏิทิน' : 'Calendar',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: Color(0xFF7C8A7C),
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
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 18,
                        color: Theme.of(context).textTheme.bodySmall?.color,
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
              children: dayHeaders
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF7C8A7C),
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
                                    borderRadius: BorderRadius.circular(5),
                                    color: isWorked
                                        ? accent
                                        : isToday
                                        ? Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surface
                                        : Colors.transparent,
                                    border: isToday && !isWorked
                                        ? Border.all(
                                            color: Theme.of(context).colorScheme.outline,
                                            width: 1,
                                          )
                                        : null,
                                    boxShadow: isWorked
                                        ? [
                                            BoxShadow(
                                              color: accent.withValues(alpha: 0.35),
                                              blurRadius: 8,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$day',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 12,
                                        fontWeight: isWorked
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                        color: isWorked
                                            ? Theme.of(context).colorScheme.onPrimary
                                            : isFuture
                                            ? Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3)
                                            : Theme.of(context).textTheme.bodyMedium?.color,
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
                _LegendDot(color: accent, label: lang == AppLanguage.th ? 'เล่นแล้ว' : 'Worked'),
                const SizedBox(width: 16),
                _LegendDot(
                  color: Theme.of(context).colorScheme.outline,
                  label: lang == AppLanguage.th ? 'ยังไม่ได้เล่น' : 'Rest',
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
                    lang == AppLanguage.th ? 'เดือนนี้ $count ครั้ง' : '$count times this month',
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
          color: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null
              ? (Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surface)
              : Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
    );
  }
}

// ─── Month Picker Dialog ──────────────────────────────────────────────────────

class _MonthPickerDialog extends StatefulWidget {
  final DateTime current;
  final DateTime maxMonth;
  final AppLanguage lang;
  const _MonthPickerDialog({required this.current, required this.maxMonth, required this.lang});

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year;

  static const _thaiMonths = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
  static const _enMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

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
    final accent = Theme.of(context).colorScheme.primary;
    final displayYear = widget.lang == AppLanguage.th ? _year + 543 : _year;
    final list = widget.lang == AppLanguage.th ? _thaiMonths : _enMonths;
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
                '$displayYear',
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
                            color: isCurrent ? accent : (Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surface),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            list[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isCurrent
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : disabled
                                  ? Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3)
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

  String _formatDate(String dateStr, AppLanguage lang) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    const thaiMonths = ['', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
    const enMonths = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = int.tryParse(parts[1]) ?? 0;
    if (lang == AppLanguage.th) {
      return '${parts[2]} ${thaiMonths[month]} ${int.parse(parts[0]) + 543}';
    } else {
      return '${parts[2]} ${enMonths[month]} ${parts[0]}';
    }
  }

  Future<void> _deleteSession(BuildContext context, AppLanguage lang) async {
    final session = await SessionDao().getByDate(widget.dateStr);
    if (session == null || session.id == null) return;

    if (!context.mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16221B),
        title: Text(
          lang == AppLanguage.th ? 'ลบประวัติการออกกำลังกาย' : 'Delete Workout Session',
          style: GoogleFonts.barlowCondensed(
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFFFFF),
          ),
        ),
        content: Text(
          lang == AppLanguage.th
              ? 'คุณต้องการลบประวัติการฝึกซ้อมของวันที่ ${_formatDate(widget.dateStr, lang)} ใช่หรือไม่?'
              : 'Are you sure you want to delete the workout history for ${_formatDate(widget.dateStr, lang)}?',
          style: GoogleFonts.sarabun(
            color: const Color(0xFF94A3B8),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              lang == AppLanguage.th ? 'ยกเลิก' : 'Cancel',
              style: GoogleFonts.sarabun(color: const Color(0xFF94A3B8)),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: Text(
              lang == AppLanguage.th ? 'ลบประวัติ' : 'Delete',
              style: GoogleFonts.sarabun(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SessionDao().delete(session.id!);
      ref.read(statsProvider.notifier).load();
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLbs = ref.watch(isLbsProvider);
    final unit = isLbs ? 'lbs' : 'kg';
    final lang = ref.watch(languageProvider);
    final accent = Theme.of(context).colorScheme.primary;
    final dateLabel = _formatDate(widget.dateStr, lang);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5)),
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
                color: Theme.of(context).colorScheme.outline,
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
                    color: widget.isWorked ? accent : Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                  ),
                ),
                const Spacer(),
                if (widget.isWorked && _data != null && _data!.isNotEmpty)
                  IconButton(
                    onPressed: () => _deleteSession(context, lang),
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: const Color(0xFFEF4444),
                    tooltip: lang == AppLanguage.th ? 'ลบประวัติวันนี้' : 'Delete Day Session',
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
                  Icon(
                    Icons.hotel_outlined,
                    size: 18,
                    color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    lang == AppLanguage.th ? 'วันพักผ่อน' : 'Rest Day',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
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
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                                  ),
                                ),
                              ),
                              Text(
                                '$wStr × ${s.reps} reps',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
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
