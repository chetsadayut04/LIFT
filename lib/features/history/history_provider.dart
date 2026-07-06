import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/exercise_dao.dart';
import '../../core/database/session_dao.dart';
import '../../core/database/set_dao.dart';
import '../../core/models/exercise.dart';
import '../../core/models/session.dart';
import '../../core/models/workout_set.dart';

class SessionSummary {
  final Session session;
  final int exerciseCount;
  final int setCount;

  const SessionSummary({
    required this.session,
    required this.exerciseCount,
    required this.setCount,
  });
}

class SessionDetail {
  final Session session;
  final List<({Exercise exercise, List<WorkoutSet> sets})> exercises;

  const SessionDetail({required this.session, required this.exercises});
}

class HistoryNotifier extends StateNotifier<AsyncValue<List<SessionSummary>>> {
  HistoryNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  final _sessionDao = SessionDao();
  final _exerciseDao = ExerciseDao();
  final _setDao = SetDao();

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final sessions = await _sessionDao.getAll();
      final summaries = <SessionSummary>[];
      for (final s in sessions) {
        final exercises = await _exerciseDao.getBySession(s.id!);
        int setCount = 0;
        for (final ex in exercises) {
          final sets = await _setDao.getByExercise(ex.id!);
          setCount += sets.where((s) => !s.isWarmup).length;
        }
        summaries.add(SessionSummary(
          session: s,
          exerciseCount: exercises.length,
          setCount: setCount,
        ));
      }
      state = AsyncValue.data(summaries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<SessionDetail> getDetail(int sessionId) async {
    final session = await _sessionDao.getById(sessionId);
    if (session == null) throw Exception('Session not found');
    final exercises = await _exerciseDao.getBySession(sessionId);
    final detail = <({Exercise exercise, List<WorkoutSet> sets})>[];
    for (final ex in exercises) {
      final sets = await _setDao.getByExercise(ex.id!);
      detail.add((exercise: ex, sets: sets));
    }
    return SessionDetail(session: session, exercises: detail);
  }

  Future<void> deleteSession(int id) async {
    await _sessionDao.delete(id);
    await load();
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, AsyncValue<List<SessionSummary>>>(
  (_) => HistoryNotifier(),
);
