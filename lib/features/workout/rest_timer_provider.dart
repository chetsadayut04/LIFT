import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestTimerState {
  final bool isRunning;
  final int secondsLeft;
  final int totalSeconds;
  final DateTime? endTime;

  const RestTimerState({
    this.isRunning = false,
    this.secondsLeft = 90,
    this.totalSeconds = 90,
    this.endTime,
  });

  double get progress => totalSeconds > 0 ? secondsLeft / totalSeconds : 0;

  RestTimerState copyWith({
    bool? isRunning,
    int? secondsLeft,
    int? totalSeconds,
    DateTime? endTime,
    bool clearEndTime = false,
  }) =>
      RestTimerState(
        isRunning: isRunning ?? this.isRunning,
        secondsLeft: secondsLeft ?? this.secondsLeft,
        totalSeconds: totalSeconds ?? this.totalSeconds,
        endTime: clearEndTime ? null : (endTime ?? this.endTime),
      );
}

class RestTimerNotifier extends StateNotifier<RestTimerState> {
  RestTimerNotifier() : super(const RestTimerState());

  Timer? _timer;

  void start({int seconds = 90}) {
    _timer?.cancel();
    final endTime = DateTime.now().add(Duration(seconds: seconds));
    state = RestTimerState(
      isRunning: true,
      secondsLeft: seconds,
      totalSeconds: seconds,
      endTime: endTime,
    );
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      final target = state.endTime;
      if (target == null) {
        t.cancel();
        return;
      }
      final remaining = target.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        t.cancel();
        state = state.copyWith(isRunning: false, secondsLeft: 0, clearEndTime: true);
      } else {
        if (state.secondsLeft != remaining) {
          state = state.copyWith(secondsLeft: remaining);
        }
      }
    });
  }

  void adjust(int delta) {
    if (state.endTime == null) return;
    final newEndTime = state.endTime!.add(Duration(seconds: delta));
    final newSecs = newEndTime.difference(DateTime.now()).inSeconds.clamp(0, 600);
    state = state.copyWith(
      endTime: newEndTime,
      secondsLeft: newSecs,
      totalSeconds: (state.totalSeconds + delta).clamp(1, 600),
    );
  }

  void skip() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false, secondsLeft: 0, clearEndTime: true);
  }

  void reset({int seconds = 90}) {
    _timer?.cancel();
    state = RestTimerState(
      isRunning: false,
      secondsLeft: seconds,
      totalSeconds: seconds,
      endTime: null,
    );
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
