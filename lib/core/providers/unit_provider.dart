import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kIsLbs = 'is_lbs';

// Overridden in main() with value loaded before runApp
final unitInitProvider = Provider<bool>((ref) => false);

/// true = lbs, false = kg
class UnitNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(unitInitProvider);

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsLbs, state);
  }

  Future<void> toggle() async {
    state = !state;
    await _save();
  }

  Future<void> set(bool isLbs) async {
    state = isLbs;
    await _save();
  }
}

final isLbsProvider = NotifierProvider<UnitNotifier, bool>(() => UnitNotifier());

const double kgToLbs = 2.20462;
const double lbsToKg = 0.453592;

String fmtNum(double v) => v.toStringAsFixed(1);

extension WeightDisplay on double {
  String display(bool isLbs) {
    final v = isLbs ? this * kgToLbs : this;
    return fmtNum(v);
  }
}

double inputToKg(double input, bool isLbs) =>
    isLbs ? input * lbsToKg : input;

// Epley formula: estimated 1-rep max
double calc1RM(double weightKg, int reps) {
  if (reps <= 1) return weightKg;
  return weightKg * (1.0 + reps / 30.0);
}

const int kRepMin = 8;
const int kRepMax = 12;

// Progressive overload: add reps until repMax, then increase weight and reset to repMin
({double weightKg, int reps, bool addedWeight}) progressionSuggestion(
    double lastWeightKg, int lastReps, {int repMin = kRepMin, int repMax = kRepMax}) {
  if (lastReps >= repMax) {
    return (weightKg: lastWeightKg + 2.5, reps: repMin, addedWeight: true);
  }
  return (weightKg: lastWeightKg, reps: lastReps + 1, addedWeight: false);
}
