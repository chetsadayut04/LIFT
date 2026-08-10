import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/home/home_provider.dart';
import '../../features/history/history_provider.dart';
import '../../features/stats/stats_provider.dart';
import '../../features/workout/active_workout_provider.dart';
import '../database/database_helper.dart';

final cacheInitProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null) return;

  // 1. Initial Cache Pull on Startup / Login
  try {
    await DatabaseHelper.clearAndPopulateCache();
    ref.invalidate(homeProvider);
    ref.invalidate(historyProvider);
    ref.invalidate(statsProvider);
    ref.read(activeWorkoutProvider.notifier).loadTodaySession();
  } catch (e) {
    if (kDebugMode) {
      print("Failed to populate cache from Supabase: $e");
    }
  }

  // 2. Set up Supabase Realtime listener to sync live updates between devices
  final supabase = Supabase.instance.client;
  final channel = supabase.channel('db-changes');

  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    callback: (payload) async {
      if (kDebugMode) {
        print("Realtime change detected, syncing cache: ${payload.toString()}");
      }
      try {
        await DatabaseHelper.clearAndPopulateCache();
        ref.invalidate(homeProvider);
        ref.invalidate(historyProvider);
        ref.invalidate(statsProvider);
        ref.read(activeWorkoutProvider.notifier).loadTodaySession();
      } catch (e) {
        if (kDebugMode) {
          print("Error updating cache on realtime change: $e");
        }
      }
    },
  ).subscribe();

  // Cancel subscription when user logs out or provider is disposed
  ref.onDispose(() {
    supabase.removeChannel(channel);
  });
});
