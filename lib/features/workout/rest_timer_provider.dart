import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestTimerState {
  final bool isRunning;
  final int secondsLeft;
  final int totalSeconds;

  const RestTimerState({
    this.isRunning = false,
    this.secondsLeft = 90,
    this.totalSeconds = 90,
  });

  double get progress => totalSeconds > 0 ? secondsLeft / totalSeconds : 0;

  RestTimerState copyWith({bool? isRunning, int? secondsLeft, int? totalSeconds}) =>
      RestTimerState(
        isRunning: isRunning ?? this.isRunning,
        secondsLeft: secondsLeft ?? this.secondsLeft,
        totalSeconds: totalSeconds ?? this.totalSeconds,
      );
}

class RestTimerNotifier extends StateNotifier<RestTimerState> {
  RestTimerNotifier() : super(const RestTimerState());

  Timer? _timer;

  void start({int seconds = 90}) {
    _timer?.cancel();
    state = RestTimerState(isRunning: true, secondsLeft: seconds, totalSeconds: seconds);
    _tick();
  }

  void _tick() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (state.secondsLeft <= 1) {
        t.cancel();
        state = state.copyWith(isRunning: false, secondsLeft: 0);
      } else {
        state = state.copyWith(secondsLeft: state.secondsLeft - 1);
      }
    });
  }

  void adjust(int delta) {
    final newSecs = (state.secondsLeft + delta).clamp(0, 600);
    state = state.copyWith(secondsLeft: newSecs);
  }

  void skip() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false, secondsLeft: 0);
  }

  void reset({int seconds = 90}) {
    _timer?.cancel();
    state = RestTimerState(secondsLeft: seconds, totalSeconds: seconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final restTimerProvider =
    StateNotifierProvider<RestTimerNotifier, RestTimerState>(
  (_) => RestTimerNotifier(),
);
