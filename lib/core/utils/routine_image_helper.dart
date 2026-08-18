import 'package:flutter/material.dart';

/// Helper utility to detect muscle groups from routine name and exercise names,
/// and provide high-quality thematic images & fallback gradients.
class RoutineImageHelper {
  static final Map<String, String> _muscleImages = {
    'upper': 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?q=80&w=800&auto=format&fit=crop',
    'chest': 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?q=80&w=800&auto=format&fit=crop',
    'lower': 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?q=80&w=800&auto=format&fit=crop',
    'leg': 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?q=80&w=800&auto=format&fit=crop',
    'back': 'https://images.unsplash.com/photo-1605296867304-46d5465a13f1?q=80&w=800&auto=format&fit=crop',
    'pull': 'https://images.unsplash.com/photo-1605296867304-46d5465a13f1?q=80&w=800&auto=format&fit=crop',
    'arm': 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?q=80&w=800&auto=format&fit=crop',
    'shoulder': 'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?q=80&w=800&auto=format&fit=crop',
    'core': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=800&auto=format&fit=crop',
    'abs': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=800&auto=format&fit=crop',
    'default': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=800&auto=format&fit=crop',
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
