import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:zane_bible_lockscreen/background/verse_worker.dart';

class WorkManagerService {
  static const _scheduledHourKey = 'daily_scheduled_hour';
  static const _scheduledMinuteKey = 'daily_scheduled_minute';

  static Future<void> scheduleDailyVerse() async {
    // Default schedule at 5:00 AM
    await scheduleDailyVerseAt(5, 0);
  }

  static Future<void> cancelDailyVerse() async {
    developer.log('Cancelling daily verse task', name: 'WorkManagerService');
    await Workmanager().cancelByUniqueName(dailyVerseUniqueName);
    await resetDailyWallpaperRetryCount();
    developer.log('Daily verse task cancelled', name: 'WorkManagerService');
  }

  static Future<String> scheduleDailyVerseAt(int hour, int minute) async {
      developer.log(
        'Scheduling daily verse at $hour:${minute.toString().padLeft(2, '0')}',
        name: 'DailyFaithSchedule',
      );

    final initial = _initialDelayFor(hour, minute);
    final nextRunText = _describeDelay(initial, hour, minute);
    developer.log(
      'Initial delay: ${initial.inSeconds} seconds (${(initial.inHours + (initial.inMinutes % 60) / 60).toStringAsFixed(1)} hours)',
      name: 'WorkManagerService',
    );

    try {
      // Save the scheduled time to SharedPreferences for later use
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_scheduledHourKey, hour);
      await prefs.setInt(_scheduledMinuteKey, minute);
      await resetDailyWallpaperRetryCount();
      developer.log('Saved scheduled time to SharedPreferences', name: 'WorkManagerService');

      // Cancel existing task before registering new one
      await Workmanager().cancelByUniqueName(dailyVerseUniqueName);

      developer.log(
        'Registering one-off task with delay ${initial.inSeconds}s',
        name: 'WorkManagerService',
      );

      // One-off WorkManager job aimed at the user-selected target time.
      // Execution is inexact: Android may delay it (Doze, standby, OEM power management).
      await Workmanager().registerOneOffTask(
        dailyVerseUniqueName,
        dailyVerseTask,
        initialDelay: initial,
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 15),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      developer.log('Successfully registered daily verse task', name: 'DailyFaithSchedule');
      developer.log(
        'Scheduled for $hour:${minute.toString().padLeft(2, '0')} daily',
        name: 'WorkManagerService',
      );
      return nextRunText;
    } catch (e, stackTrace) {
      developer.log('Error registering task: $e', name: 'WorkManagerService', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Delay until the next run at [hour]:[minute].
  ///
  /// [DateTime] constructed from a [TimeOfDay] is at second 0 of that minute.
  /// Confirming the picker on the current minute therefore looks "in the past"
  /// and used to jump to tomorrow (~24h). A short grace window runs soon instead.
  static Duration _initialDelayFor(int hour, int minute) {
    final now = DateTime.now();
    var nextRun = DateTime(now.year, now.month, now.day, hour, minute);

    if (nextRun.isAfter(now)) {
      developer.log(
        'Scheduling for today at $hour:${minute.toString().padLeft(2, '0')}',
        name: 'DailyFaithSchedule',
      );
      return nextRun.difference(now);
    }

    final overdue = now.difference(nextRun);
    if (overdue < const Duration(minutes: 3)) {
      const soon = Duration(seconds: 20);
      developer.log(
        'Selected time is the current or just-passed minute; first run in ${soon.inSeconds}s (not tomorrow)',
        name: 'DailyFaithSchedule',
      );
      return soon;
    }

    nextRun = nextRun.add(const Duration(days: 1));
    developer.log(
      'Scheduled time already passed today, scheduling for tomorrow at $hour:${minute.toString().padLeft(2, '0')}',
      name: 'DailyFaithSchedule',
    );
    return nextRun.difference(now);
  }

  static String describeNextRun(int hour, int minute) {
    return _describeDelay(_initialDelayFor(hour, minute), hour, minute);
  }

  static String _describeDelay(Duration delay, int hour, int minute) {
    if (delay.inHours >= 12) {
      return 'Next run tomorrow around ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}. Android may delay it.';
    }
    if (delay.inMinutes < 1) {
      return 'Next run in about a minute. Android may delay it slightly.';
    }
    return 'Next run in about ${delay.inMinutes} minutes. Android may delay it.';
  }
}
