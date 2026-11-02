import 'package:flutter_test/flutter_test.dart';
import 'package:weightlifting_tracker/features/stats/stats_provider.dart';

void main() {
  group('WeeklyStats.percentChange (TC-10)', () {
    test('calculates positive percent change correctly', () {
      const stats = WeeklyStats(
        thisWeekVolume: 150.0,
        lastWeekVolume: 100.0,
        thisWeekPerExercise: {},
        lastWeekPerExercise: {},
      );
      expect(stats.percentChange, 50.0);
    });

    test('calculates negative percent change correctly', () {
      const stats = WeeklyStats(
        thisWeekVolume: 50.0,
        lastWeekVolume: 100.0,
        thisWeekPerExercise: {},
        lastWeekPerExercise: {},
      );
      expect(stats.percentChange, -50.0);
    });

    test('returns 0.0 when volume is unchanged', () {
      const stats = WeeklyStats(
        thisWeekVolume: 100.0,
        lastWeekVolume: 100.0,
        thisWeekPerExercise: {},
        lastWeekPerExercise: {},
      );
      expect(stats.percentChange, 0.0);
    });

    test('returns null when lastWeekVolume is 0 and thisWeekVolume > 0', () {
      const stats = WeeklyStats(
        thisWeekVolume: 100.0,
        lastWeekVolume: 0.0,
        thisWeekPerExercise: {},
        lastWeekPerExercise: {},
      );
      expect(stats.percentChange, isNull);
    });

    test('returns null when both volumes are 0', () {
      const stats = WeeklyStats(
        thisWeekVolume: 0.0,
        lastWeekVolume: 0.0,
        thisWeekPerExercise: {},
        lastWeekPerExercise: {},
      );
      expect(stats.percentChange, isNull);
    });
  });
}

