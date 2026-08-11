import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:live_activities/live_activities.dart';

class BackgroundTimerService {
  static final BackgroundTimerService _instance = BackgroundTimerService._internal();
  factory BackgroundTimerService() => _instance;
  BackgroundTimerService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final LiveActivities _liveActivities = LiveActivities();
  String? _activityId;

  final StreamController<String> _actionController = StreamController<String>.broadcast();
  Stream<String> get actionStream => _actionController.stream;

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize local notifications for Android
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final actionId = response.actionId;
        if (actionId != null) {
          _actionController.add(actionId);
        }
      },
    );

    // Initialize iOS Live Activities App Group
    if (Platform.isIOS) {
      try {
        await _liveActivities.init(appGroupId: "group.com.weightliftingtracker.lift");
      } catch (e) {
        debugPrint("Live activities init error: $e");
      }
    }

    _isInitialized = true;
  }

  Future<void> start(DateTime endTime, int totalSeconds) async {
    await init();

    // 1. Android Notification using Chronometer
    if (Platform.isAndroid) {
      final androidDetails = AndroidNotificationDetails(
        'rest_timer_channel',
        'Rest Timer',
        channelDescription: 'Displays workout rest timer countdown',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        onlyAlertOnce: true,
        showWhen: true,
        when: endTime.millisecondsSinceEpoch,
        usesChronometer: true,
        chronometerCountDown: true,
        actions: const [
          AndroidNotificationAction('add_30s', '+30s'),
          AndroidNotificationAction('skip', 'Skip'),
        ],
      );

      final details = NotificationDetails(android: androidDetails);
      await _localNotifications.show(
        888, // Notification ID
        'Resting...',
        'Time to recover',
        details,
      );
    }

    // 2. iOS Live Activity
    if (Platform.isIOS) {
      try {
        if (await _liveActivities.areActivitiesEnabled()) {
          final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
          _activityId = await _liveActivities.createActivity(
            uniqueId,
            {
              "endTime": endTime.millisecondsSinceEpoch,
            },
          );
        }
      } catch (e) {
        // Silent catch for iOS when no Swift extension is configured yet
        debugPrint("Live activities error: $e");
      }
    }
  }

  Future<void> update(DateTime endTime) async {
    await init();

    // 1. Android update notification with new end time
    if (Platform.isAndroid) {
      final androidDetails = AndroidNotificationDetails(
        'rest_timer_channel',
        'Rest Timer',
        channelDescription: 'Displays workout rest timer countdown',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        onlyAlertOnce: true,
        showWhen: true,
        when: endTime.millisecondsSinceEpoch,
        usesChronometer: true,
        chronometerCountDown: true,
        actions: const [
          AndroidNotificationAction('add_30s', '+30s'),
          AndroidNotificationAction('skip', 'Skip'),
        ],
      );

      final details = NotificationDetails(android: androidDetails);
      await _localNotifications.show(
        888,
        'Resting...',
        'Time to recover',
        details,
      );
    }

    // 2. iOS update Live Activity
    if (Platform.isIOS && _activityId != null) {
      try {
        await _liveActivities.updateActivity(_activityId!, {
          "endTime": endTime.millisecondsSinceEpoch,
        });
      } catch (e) {
        debugPrint("Live activities update error: $e");
      }
    }
  }

  Future<void> stop() async {
    // 1. Android dismiss notification
    if (Platform.isAndroid) {
      await _localNotifications.cancel(888);
    }

    // 2. iOS end Live Activity
    if (Platform.isIOS && _activityId != null) {
      try {
        await _liveActivities.endActivity(_activityId!);
        _activityId = null;
      } catch (e) {
        debugPrint("Live activities stop error: $e");
      }
    }
  }
}
