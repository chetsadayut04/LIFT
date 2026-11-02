import 'package:flutter_test/flutter_test.dart';
import 'package:weightlifting_tracker/core/providers/unit_provider.dart';

void main() {
  group('calc1RM', () {
    test('calculates estimated 1RM for standard reps using Epley formula', () {
      expect(calc1RM(100.0, 10), closeTo(133.33, 0.01));
      expect(calc1RM(60.0, 5), closeTo(70.0, 0.01));
    });

    test('returns original weight when reps <= 1', () {
      expect(calc1RM(100.0, 1), 100.0);
      expect(calc1RM(100.0, 0), 100.0);
    });
  });

  group('inputToKg', () {
    test('returns original value when isLbs is false', () {
      expect(inputToKg(100.0, false), 100.0);
    });

    test('converts lbs to kg correctly when isLbs is true', () {
      expect(inputToKg(220.462, true), closeTo(100.0, 0.01));
    });
  });

  group('WeightDisplay', () {
    test('formats kg and lbs display values', () {
      expect(100.0.display(false), '100.0');
      expect(100.0.display(true), '220.5');
    });

    test('TC-08: display is idempotent and survives round trip conversion', () {
      const weightKg = 100.0;
      final first = weightKg.display(true);
      final second = weightKg.display(true);
      final third = weightKg.display(true);

      expect(first, '220.5');
      expect(second, first);
      expect(third, first);

      final parsedLbs = double.parse(first);
      final roundTripKg = inputToKg(parsedLbs, true);
      expect(roundTripKg, closeTo(weightKg, 0.05));
    });
  });

  group('fmtNum', () {
    test('formats numbers to one decimal place', () {
      expect(fmtNum(0.0), '0.0');
      expect(fmtNum(12.34), '12.3');
    });
  });

  group('progressionSuggestion', () {
    test('suggests weight increase when hitting repMax', () {
      final result = progressionSuggestion(60.0, 12);
      expect(result.weightKg, 62.5);
      expect(result.reps, 8);
      expect(result.addedWeight, true);
    });

    test('suggests adding reps when below repMax', () {
      final result1 = progressionSuggestion(60.0, 8);
      expect(result1.weightKg, 60.0);
      expect(result1.reps, 9);
      expect(result1.addedWeight, false);

      final result2 = progressionSuggestion(60.0, 11);
      expect(result2.weightKg, 60.0);
      expect(result2.reps, 12);
      expect(result2.addedWeight, false);
    });

    test('respects custom repMin and repMax boundaries', () {
      final result = progressionSuggestion(60.0, 5, repMin: 5, repMax: 5);
      expect(result.weightKg, 62.5);
      expect(result.reps, 5);
      expect(result.addedWeight, true);
    });
  });
}

