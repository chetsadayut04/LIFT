import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/exercise_dao.dart';
import '../../core/database/session_dao.dart';
import '../../core/database/set_dao.dart';

class WeeklyStats {
  final double thisWeekVolume;
  final double lastWeekVolume;
  final Map<String, double> thisWeekPerExercise;
  final Map<String, double> lastWeekPerExercise;

  const WeeklyStats({
    required this.thisWeekVolume,
    required this.lastWeekVolume,
    required this.thisWeekPerExercise,
    required this.lastWeekPerExercise,
  });

  double? get percentChange {
    if (lastWeekVolume == 0) return null;
    return (thisWeekVolume - lastWeekVolume) / lastWeekVolume * 100;
  }
}

class StatsState {
  final bool isLoading;
  final WeeklyStats? weekly;
  final int thisWeekSets;
  final int lastWeekSets;
  final List<String> exerciseNames;
  final String? selectedExercise;
  final List<({String dateStr, double volume})> exerciseHistory;
  final List<({String dateStr, double maxWeight})> maxWeightHistory;
  final List<double> thisWeekDaily;
  final List<double> lastWeekDaily;
  final Set<String> workoutDates;
  final List<({String name, double prKg, int prReps, int totalSets})> exercisePrs;

  const StatsState({
    this.isLoading = true,
    this.weekly,
    this.thisWeekSets = 0,
    this.lastWeekSets = 0,
    this.exerciseNames = const [],
    this.selectedExercise,
    this.exerciseHistory = const [],
    this.maxWeightHistory = const [],
    this.thisWeekDaily = const [0, 0, 0, 0, 0, 0, 0],
    this.lastWeekDaily = const [0, 0, 0, 0, 0, 0, 0],
    this.workoutDates = const {},
    this.exercisePrs = const [],
  });

  StatsState copyWith({
    bool? isLoading,
    WeeklyStats? weekly,
    int? thisWeekSets,
    int? lastWeekSets,
    List<String>? exerciseNames,
    String? selectedExercise,
    List<({String dateStr, double volume})>? exerciseHistory,
    List<({String dateStr, double maxWeight})>? maxWeightHistory,
    List<double>? thisWeekDaily,
    List<double>? lastWeekDaily,
    Set<String>? workoutDates,
    List<({String name, double prKg, int prReps, int totalSets})>? exercisePrs,
  }) =>
      StatsState(
        isLoading: isLoading ?? this.isLoading,
        weekly: weekly ?? this.weekly,
        thisWeekSets: thisWeekSets ?? this.thisWeekSets,
        lastWeekSets: lastWeekSets ?? this.lastWeekSets,
        exerciseNames: exerciseNames ?? this.exerciseNames,
        selectedExercise: selectedExercise ?? this.selectedExercise,
        exerciseHistory: exerciseHistory ?? this.exerciseHistory,
        maxWeightHistory: maxWeightHistory ?? this.maxWeightHistory,
        thisWeekDaily: thisWeekDaily ?? this.thisWeekDaily,
        lastWeekDaily: lastWeekDaily ?? this.lastWeekDaily,
        workoutDates: workoutDates ?? this.workoutDates,
        exercisePrs: exercisePrs ?? this.exercisePrs,
      );
}

class StatsNotifier extends StateNotifier<StatsState> {
  StatsNotifier() : super(const StatsState()) {
    load();
  }

  final _setDao = SetDao();
  final _exerciseDao = ExerciseDao();
  final _sessionDao = SessionDao();

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final now = DateTime.now();
    final thisMonday = now.subtract(Duration(days: now.weekday - 1));
    final lastMonday = thisMonday.subtract(const Duration(days: 7));
    final thisSunday = thisMonday.add(const Duration(days: 6));
    final lastSunday = lastMonday.add(const Duration(days: 6));

    final thisWeekVol = await _setDao.getTotalVolumeByDateRange(
        _fmt(thisMonday), _fmt(thisSunday));
    final lastWeekVol = await _setDao.getTotalVolumeByDateRange(
        _fmt(lastMonday), _fmt(lastSunday));
    final thisWeekPerEx = await _setDao.getVolumePerExerciseByDateRange(
        _fmt(thisMonday), _fmt(thisSunday));
    final lastWeekPerEx = await _setDao.getVolumePerExerciseByDateRange(
        _fmt(lastMonday), _fmt(lastSunday));

    final names = await _exerciseDao.getAllNames();

    final thisWeekDailyMap = await _setDao.getVolumePerDay(_fmt(thisMonday), _fmt(thisSunday));
    final lastWeekDailyMap = await _setDao.getVolumePerDay(_fmt(lastMonday), _fmt(lastSunday));
    final workoutDates = await _sessionDao.getAllDates(); // all sessions for calendar
    final thisWeekSets = await _setDao.getTotalSetsByDateRange(_fmt(thisMonday), _fmt(thisSunday));
    final lastWeekSets = await _setDao.getTotalSetsByDateRange(_fmt(lastMonday), _fmt(lastSunday));
    final exercisePrs = await _setDao.getAllExercisePrs();

    state = state.copyWith(
      isLoading: false,
      weekly: WeeklyStats(
        thisWeekVolume: thisWeekVol,
        lastWeekVolume: lastWeekVol,
        thisWeekPerExercise: thisWeekPerEx,
        lastWeekPerExercise: lastWeekPerEx,
      ),
      thisWeekSets: thisWeekSets,
      lastWeekSets: lastWeekSets,
      exerciseNames: names,
      thisWeekDaily: List.generate(
          7, (i) => thisWeekDailyMap[_fmt(thisMonday.add(Duration(days: i)))] ?? 0.0),
      lastWeekDaily: List.generate(
          7, (i) => lastWeekDailyMap[_fmt(lastMonday.add(Duration(days: i)))] ?? 0.0),
      workoutDates: workoutDates,
      exercisePrs: exercisePrs,
    );
  }

  Future<void> selectExercise(String name) async {
    state = state.copyWith(selectedExercise: name, isLoading: true);
    final latestDate = await _setDao.getLatestDateForExercise(name);
    final anchor = latestDate ?? DateTime.now();
    // Go back 6 weeks from anchor, then collect each day with data
    final anchorMonday = anchor.subtract(Duration(days: anchor.weekday - 1));
    final fromDate = anchorMonday.subtract(const Duration(days: 41)); // 6 weeks back
    final toDate = anchorMonday.add(const Duration(days: 6));
    final from = _fmt(fromDate);
    final to = _fmt(toDate);
    final volPerDayF = _setDao.getVolumePerDayForExercise(name, from, to);
    final maxPerDayF = _setDao.getMaxWeightPerDayForExercise(name, from, to);
    final volPerDay = await volPerDayF;
    final maxPerDay = await maxPerDayF;

    final sortedKeys = ({...volPerDay.keys, ...maxPerDay.keys}.toList()..sort());
    final history = sortedKeys.map((d) => (dateStr: d, volume: volPerDay[d] ?? 0.0)).toList();
    final maxHistory = sortedKeys.map((d) => (dateStr: d, maxWeight: maxPerDay[d] ?? 0.0)).toList();
    state = state.copyWith(isLoading: false, exerciseHistory: history, maxWeightHistory: maxHistory);
  }

  /// Returns [(exerciseName, sets)] for a given date, or empty if no session.
  Future<List<({String name, List<({int reps, double weightKg})> sets})>>
      getDayDetail(String dateStr) async {
    final session = await _sessionDao.getByDate(dateStr);
    if (session == null) return [];
    final exercises = await _exerciseDao.getBySession(session.id!);
    final result =
        <({String name, List<({int reps, double weightKg})> sets})>[];
    for (final ex in exercises) {
      final rawSets = await _setDao.getByExercise(ex.id!);
      result.add((
        name: ex.name,
        sets: rawSets
            .map((s) => (reps: s.reps, weightKg: s.weightKg))
            .toList(),
      ));
    }
    return result;
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final statsProvider = StateNotifierProvider<StatsNotifier, StatsState>(
  (_) => StatsNotifier(),
);
