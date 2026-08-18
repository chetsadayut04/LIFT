import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/routine_dao.dart';
import '../../core/models/routine.dart';
import '../../core/models/routine_exercise.dart';
import '../../core/models/routine_set.dart';

class RoutineExerciseWithSets {
  final RoutineExercise exercise;
  final List<RoutineSet> sets;

  RoutineExerciseWithSets({required this.exercise, required this.sets});
}

class RoutineWithDetails {
  final Routine routine;
  final List<RoutineExerciseWithSets> exercises;

  RoutineWithDetails({required this.routine, required this.exercises});
}

class RoutineState {
  final List<RoutineWithDetails> routines;
  final bool isLoading;

  const RoutineState({
    this.routines = const [],
    this.isLoading = false,
  });

  RoutineState copyWith({
    List<RoutineWithDetails>? routines,
    bool? isLoading,
  }) => RoutineState(
        routines: routines ?? this.routines,
        isLoading: isLoading ?? this.isLoading,
      );
}

class RoutineNotifier extends StateNotifier<RoutineState> {
  final _dao = RoutineDao();

  RoutineNotifier() : super(const RoutineState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final list = await _dao.getRoutines();
    final List<RoutineWithDetails> detailsList = [];

    for (final r in list) {
      final exercises = await _dao.getExercisesForRoutine(r.id!);
      final List<RoutineExerciseWithSets> exWithSets = [];
      for (final ex in exercises) {
        final sets = await _dao.getSetsForExercise(ex.id!);
        exWithSets.add(RoutineExerciseWithSets(exercise: ex, sets: sets));
      }
      detailsList.add(RoutineWithDetails(routine: r, exercises: exWithSets));
    }

    state = state.copyWith(routines: detailsList, isLoading: false);
  }

  Future<void> addRoutine(String name, List<Map<String, dynamic>> exercises) async {
    await _dao.saveFullRoutine(name: name, exercises: exercises);
    await load();
  }

  Future<void> updateRoutine(int routineId, String name, List<Map<String, dynamic>> exercises) async {
    await _dao.updateFullRoutine(routineId: routineId, name: name, exercises: exercises);
    await load();
  }

  Future<void> deleteRoutine(int id) async {
    await _dao.deleteRoutine(id);
    await load();
  }
}

final routineProvider = StateNotifierProvider<RoutineNotifier, RoutineState>(
  (_) => RoutineNotifier(),
);
