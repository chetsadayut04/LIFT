import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/session_dao.dart';
import '../../core/database/set_dao.dart';

typedef ExerciseSummary = ({
  String name,
  int setCount,
  double avgWeight,
  double totalVolume,
  double bestE1rm,
  bool hasPrToday,
});

class HomeState {
  final bool hasSessionToday;
  final bool isFinishedToday;
  final double thisWeekVolume;
  final double lastWeekVolume;
  final double todayVolume;
  final List<ExerciseSummary> todayExercises;
  final int streak;
  final bool isLoading;
  final String? sessionName;
  final int? sessionStartedAt;
  final int? sessionFinishedAt;
  final double lastSessionVolume;
  final double bestE1RMToday;
  final String? bestE1RMExercise;

  const HomeState({
    this.hasSessionToday = false,
    this.isFinishedToday = false,
    this.thisWeekVolume = 0,
    this.lastWeekVolume = 0,
    this.todayVolume = 0,
    this.todayExercises = const [],
    this.streak = 0,
    this.isLoading = true,
    this.sessionName,
    this.sessionStartedAt,
    this.sessionFinishedAt,
    this.lastSessionVolume = 0,
    this.bestE1RMToday = 0,
    this.bestE1RMExercise,
  });

  double? get percentChange {
    if (lastWeekVolume == 0) return null;
    return (thisWeekVolume - lastWeekVolume) / lastWeekVolume * 100;
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier() : super(const HomeState()) {
    load();
  }

  final _sessionDao = SessionDao();
  final _setDao = SetDao();

  Future<void> load() async {
    state = const HomeState(isLoading: true);
    try {
      final today = _fmt(DateTime.now());
      final stale = await _sessionDao.getStaleActiveSessions(today);
      for (final s in stale) {
        await _sessionDao.finishSession(s.id!);
      }
      final session = await _sessionDao.getByDate(today);

      final now = DateTime.now();
      final thisMonday = now.subtract(Duration(days: now.weekday - 1));
      final lastMonday = thisMonday.subtract(const Duration(days: 7));
      final thisSunday = thisMonday.add(const Duration(days: 6));
      final lastSunday = lastMonday.add(const Duration(days: 6));

      final results = await Future.wait([
        _setDao.getTotalVolumeByDateRange(_fmt(thisMonday), _fmt(thisSunday)),
        _setDao.getTotalVolumeByDateRange(_fmt(lastMonday), _fmt(lastSunday)),
        _setDao.getTotalVolumeByDateRange(today, today),
        _setDao.getExerciseSummaryByDate(today),
        _sessionDao.getFinishedDates(),
        _setDao.getLastSessionVolumeBeforeDate(today),
      ]);

      final exercises = results[3] as List<ExerciseSummary>;
      final finishedDates = results[4] as Set<String>;
      final streak = _calcStreak(finishedDates, now);

      double bestE1RM = 0;
      String? bestE1RMExercise;
      for (final ex in exercises) {
        if (ex.bestE1rm > bestE1RM) {
          bestE1RM = ex.bestE1rm;
          bestE1RMExercise = ex.name;
        }
      }

      state = HomeState(
        hasSessionToday: session != null,
        isFinishedToday: session?.isFinished ?? false,
        thisWeekVolume: results[0] as double,
        lastWeekVolume: results[1] as double,
        todayVolume: results[2] as double,
        todayExercises: exercises,
        streak: streak,
        isLoading: false,
        sessionName: session?.name,
        sessionStartedAt: session?.createdAt,
        sessionFinishedAt: session?.finishedAt,
        lastSessionVolume: results[5] as double,
        bestE1RMToday: bestE1RM,
        bestE1RMExercise: bestE1RMExercise,
      );
    } catch (_) {
      state = const HomeState(isLoading: false);
    }
  }

  Future<void> finishSession() async {
    final today = _fmt(DateTime.now());
    final session = await _sessionDao.getByDate(today);
    if (session?.id != null) {
      await _sessionDao.finishSession(session!.id!);
    }
    await load();
  }

  Future<void> reopenSession() async {
    final today = _fmt(DateTime.now());
    final session = await _sessionDao.getByDate(today);
    if (session?.id != null) {
      await _sessionDao.reopenSession(session!.id!);
    }
    await load();
  }

  int _calcStreak(Set<String> dates, DateTime from) {
    var d = from;
    if (!dates.contains(_fmt(d))) {
      d = d.subtract(const Duration(days: 1));
      if (!dates.contains(_fmt(d))) {
        return 0;
      }
    }

    int streak = 0;
    while (dates.contains(_fmt(d))) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>(
  (_) => HomeNotifier(),
);
