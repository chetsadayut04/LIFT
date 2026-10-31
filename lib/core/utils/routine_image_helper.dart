/// Helper utility to detect muscle groups from routine name and exercise names,
/// and provide high-quality thematic images & fallback gradients.
class RoutineImageHelper {
  static final Map<String, String> _muscleImages = {
    'upper': 'assets/images/muscle_chest.webp',
    'chest': 'assets/images/muscle_chest.webp',
    'lower': 'assets/images/muscle_legs.webp',
    'leg': 'assets/images/muscle_legs.webp',
    'back': 'assets/images/muscle_back.webp',
    'pull': 'assets/images/muscle_back.webp',
    'arm': 'assets/images/muscle_arm.webp',
    'shoulder': 'assets/images/muscle_shoulder.webp',
    'core': 'assets/images/muscle_core.webp',
    'abs': 'assets/images/muscle_core.webp',
    'default': 'assets/images/muscle_default.webp',
  };

  /// Returns an image URL based on [routineName] and optional [exerciseNames].
  static String getImageUrl(String routineName, [List<String>? exerciseNames]) {
    final nameLower = routineName.toLowerCase();

    if (nameLower.contains('upper') || nameLower.contains('chest') || nameLower.contains('push') || nameLower.contains('bench')) {
      return _muscleImages['chest']!;
    }
    if (nameLower.contains('lower') || nameLower.contains('leg') || nameLower.contains('squat') || nameLower.contains('quad')) {
      return _muscleImages['leg']!;
    }
    if (nameLower.contains('back') || nameLower.contains('pull') || nameLower.contains('lat') || nameLower.contains('row')) {
      return _muscleImages['back']!;
    }
    if (nameLower.contains('shoulder') || nameLower.contains('delt') || nameLower.contains('ohp')) {
      return _muscleImages['shoulder']!;
    }
    if (nameLower.contains('arm') || nameLower.contains('bicep') || nameLower.contains('tricep') || nameLower.contains('curl')) {
      return _muscleImages['arm']!;
    }
    if (nameLower.contains('abs') || nameLower.contains('core') || nameLower.contains('crunch')) {
      return _muscleImages['core']!;
    }

    // Secondary check: inspect exercise names if routine name is generic (e.g. "Day 1", "Routine A")
    if (exerciseNames != null && exerciseNames.isNotEmpty) {
      final combinedExercises = exerciseNames.join(' ').toLowerCase();

      if (combinedExercises.contains('squat') || combinedExercises.contains('leg') || combinedExercises.contains('lunge')) {
        return _muscleImages['leg']!;
      }
      if (combinedExercises.contains('bench') || combinedExercises.contains('chest') || combinedExercises.contains('pushup')) {
        return _muscleImages['chest']!;
      }
      if (combinedExercises.contains('pullup') || combinedExercises.contains('lat') || combinedExercises.contains('row')) {
        return _muscleImages['back']!;
      }
      if (combinedExercises.contains('shoulder') || combinedExercises.contains('press') || combinedExercises.contains('delt')) {
        return _muscleImages['shoulder']!;
      }
      if (combinedExercises.contains('curl') || combinedExercises.contains('tricep') || combinedExercises.contains('bicep')) {
        return _muscleImages['arm']!;
      }
    }

    return _muscleImages['default']!;
  }
}