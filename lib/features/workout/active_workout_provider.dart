import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/exercise_config_dao.dart';
import '../../core/database/exercise_dao.dart';
import '../../core/database/session_dao.dart';
import '../../core/database/set_dao.dart';
import '../../core/models/exercise.dart';
import '../../core/models/exercise_config.dart';
import '../../core/models/session.dart';
import '../../core/models/workout_set.dart';

class ExerciseWithSets {
  final Exercise exercise;
  final List<WorkoutSet> sets;
  final List<({double weight, int reps})> lastSessionSets;
  final double? prKg;
  final int repMin;
  final int repMax;

  ExerciseWithSets(this.exercise, this.sets, {
    this.lastSessionSets = const [],
    this.prKg,
    this.repMin = 8,
    this.repMax = 12,
  });

  ExerciseWithSets copyWith({
    List<WorkoutSet>? sets,
    List<({double weight, int reps})>? lastSessionSets,
    double? prKg,
    int? repMin,
    int? repMax,
  }) =>
      ExerciseWithSets(
        exercise,
        sets ?? this.sets,
        lastSessionSets: lastSessionSets ?? this.lastSessionSets,
        prKg: prKg ?? this.prKg,
        repMin: repMin ?? this.repMin,
        repMax: repMax ?? this.repMax,
      );
}

class ActiveWorkoutState {
  final Session? session;
  final List<ExerciseWithSets> exercises;
  final bool isLoading;

  const ActiveWorkoutState({
    this.session,
    this.exercises = const [],
    this.isLoading = false,
  });

  ActiveWorkoutState copyWith({
    Session? session,
    List<ExerciseWithSets>? exercises,
    bool? isLoading,
  }) =>
      ActiveWorkoutState(
        session: session ?? this.session,
        exercises: exercises ?? this.exercises,
        isLoading: isLoading ?? this.isLoading,
      );
}

class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState> {
  ActiveWorkoutNotifier() : super(const ActiveWorkoutState());

  final _sessionDao = SessionDao();
  final _exerciseDao = ExerciseDao();
  final _setDao = SetDao();
  final _configDao = ExerciseConfigDao();

  Future<void> startSession({String? name}) async {
    final today = _todayString();
    var session = await _sessionDao.getByDate(today);
    session ??= await _sessionDao.insert(
      Session(date: today, name: name?.trim().isEmpty ?? true ? null : name?.trim(), createdAt: DateTime.now().millisecondsSinceEpoch),
    );
    await _loadSession(session);
  }

  Future<void> loadTodaySession() async {
    final today = _todayString();
    final session = await _sessionDao.getByDate(today);
    if (session != null) await _loadSession(session);
  }

  Future<void> _loadSession(Session session) async {
    final exercises = await _exerciseDao.getBySession(session.id!);
    final exercisesWithSets = await Future.wait(exercises.map((ex) async {
      final results = await Future.wait([
        _setDao.getByExercise(ex.id!),
        _setDao.getLastSessionSetsForExercise(ex.name, session.date),
        _setDao.getPrWeightForExercise(ex.name),
        _configDao.get(ex.name),
      ]);
      final cfg = results[3] as ExerciseConfig;
      return ExerciseWithSets(
        ex,
        results[0] as List<WorkoutSet>,
        lastSessionSets: results[1] as List<({double weight, int reps})>,
        prKg: results[2] as double?,
        repMin: cfg.repMin,
        repMax: cfg.repMax,
      );
    }));
    state = state.copyWith(session: session, exercises: exercisesWithSets);
  }

  Future<void> addExercise(String name) async {
    if (state.session == null) return;
    final trimmed = name.trim();
    final exercise = await _exerciseDao.insert(Exercise(
      sessionId: state.session!.id!,
      name: trimmed,
      orderIndex: state.exercises.length,
    ));
    final results = await Future.wait([
      _setDao.getLastSessionSetsForExercise(trimmed, state.session!.date),
      _setDao.getPrWeightForExercise(trimmed),
      _configDao.get(trimmed),
    ]);
    final cfg = results[2] as ExerciseConfig;
    state = state.copyWith(
      exercises: [
        ...state.exercises,
        ExerciseWithSets(exercise, [],
            lastSessionSets: results[0] as List<({double weight, int reps})>,
            prKg: results[1] as double?,
            repMin: cfg.repMin,
            repMax: cfg.repMax),
      ],
    );
  }

  Future<void> updateRepRange(int exerciseId, int repMin, int repMax) async {
    final idx = state.exercises.indexWhere((e) => e.exercise.id == exerciseId);
    if (idx == -1) return;
    final ex = state.exercises[idx];
    await _configDao.save(ExerciseConfig(name: ex.exercise.name, repMin: repMin, repMax: repMax));
    final updated = List<ExerciseWithSets>.from(state.exercises);
    updated[idx] = ex.copyWith(repMin: repMin, repMax: repMax);
    state = state.copyWith(exercises: updated);
  }

  Future<void> addSet(int exerciseId, double weightKg, int reps, {bool isWarmup = false}) async {
    final idx = state.exercises.indexWhere((e) => e.exercise.id == exerciseId);
    if (idx == -1) return;
    final cur = state.exercises[idx];
    final setNumber = cur.sets.length + 1;
    final newSet = await _setDao.insert(WorkoutSet(
      exerciseId: exerciseId,
      setNumber: setNumber,
      weightKg: weightKg,
      reps: reps,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      isWarmup: isWarmup,
    ));
    final newPr = (!isWarmup && weightKg > (cur.prKg ?? 0)) ? weightKg : cur.prKg;
    final updated = List<ExerciseWithSets>.from(state.exercises);
    updated[idx] = cur.copyWith(sets: [...cur.sets, newSet], prKg: newPr);
    state = state.copyWith(exercises: updated);
  }

  Future<void> deleteSet(int exerciseId, int setId) async {
    await _setDao.delete(setId);
    await _setDao.renumberSets(exerciseId);
    final idx = state.exercises.indexWhere((e) => e.exercise.id == exerciseId);
    if (idx == -1) return;
    final updated = List<ExerciseWithSets>.from(state.exercises);
    final cur = updated[idx];
    final remaining = cur.sets.where((s) => s.id != setId).toList();
    final renumbered = [
      for (var i = 0; i < remaining.length; i++)
        remaining[i].copyWith(setNumber: i + 1),
    ];
    updated[idx] = cur.copyWith(sets: renumbered);
    state = state.copyWith(exercises: updated);
  }

  Future<void> reorderExercises(int oldIndex, int newIndex) async {
    final list = List<ExerciseWithSets>.from(state.exercises);
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = state.copyWith(exercises: list);
    await Future.wait([
      for (var i = 0; i < list.length; i++)
        _exerciseDao.updateOrderIndex(list[i].exercise.id!, i),
    ]);
  }

  Future<void> deleteExercise(int exerciseId) async {
    await _exerciseDao.delete(exerciseId);
    final remaining = state.exercises.where((e) => e.exercise.id != exerciseId).toList();
    state = state.copyWith(exercises: remaining);
    await Future.wait([
      for (var i = 0; i < remaining.length; i++)
        _exerciseDao.updateOrderIndex(remaining[i].exercise.id!, i),
    ]);
  }

  Future<void> renameExercise(int exerciseId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _exerciseDao.updateName(exerciseId, trimmed);
    final updated = state.exercises.map((e) {
      if (e.exercise.id == exerciseId) {
        return ExerciseWithSets(e.exercise.copyWith(name: trimmed), e.sets,
            lastSessionSets: e.lastSessionSets, prKg: e.prKg);
      }
      return e;
    }).toList();
    state = state.copyWith(exercises: updated);
  }

  Future<void> startSessionFromTemplate(String? name, List<String> exerciseNames) async {
    await startSession(name: name);
    for (final exerciseName in exerciseNames) {
      await addExercise(exerciseName);
    }
  }

  Future<void> renameSession(String name) async {
    if (state.session == null) return;
    await _sessionDao.updateName(state.session!.id!, name);
    state = state.copyWith(session: state.session!.copyWith(name: name));
  }

  Future<void> finishSession() async {
    if (state.session == null) return;
    await _sessionDao.finishSession(state.session!.id!);
    clearSession();
  }

  void clearSession() {
    state = const ActiveWorkoutState();
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState>(
  (_) => ActiveWorkoutNotifier(),
);
