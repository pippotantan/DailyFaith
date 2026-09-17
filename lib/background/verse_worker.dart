import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:zane_bible_lockscreen/core/services/auto_wallpaper_service.dart';

const dailyVerseTask = 'dailyVerseWallpaper';
const dailyVerseUniqueName = 'dailyVerseTask';

// Keys must match what SettingsService uses
const _scheduledHourKey = 'daily_scheduled_hour';
const _scheduledMinuteKey = 'daily_scheduled_minute';
const _retryCountKey = 'daily_wallpaper_retry_count';
const _maxRetries = 3;

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Initialize Flutter bindings for background execution
    WidgetsFlutterBinding.ensureInitialized();

    try {
      developer.log('Task received: $task', name: 'DailyFaithSchedule');
      switch (task) {
        case dailyVerseTask:
          developer.log('Starting AutoWallpaperService.run()', name: 'DailyFaithSchedule');
          bool success = false;
          try {
            await AutoWallpaperService.run();
            developer.log(
              'AutoWallpaperService.run() completed successfully',
              name: 'DailyFaithSchedule',
            );
            success = true;
          } catch (e) {
            developer.log('AutoWallpaperService.run() failed: $e', name: 'DailyFaithSchedule');
          }

          if (success) {
            await resetDailyWallpaperRetryCount();
            await _rescheduleForNextDay();
          } else {
            await _scheduleBoundedRetryOrNextDay();
          }
          break;
        default:
          developer.log('Unknown task: $task', name: 'BackgroundWorker');
          return Future.value(false); // Unknown task
      }
      return Future.value(true);
    } catch (e, stackTrace) {
      developer.log('Task error: $e', name: 'BackgroundWorker', stackTrace: stackTrace);
      try {
        await _scheduleBoundedRetryOrNextDay();
      } catch (rescheduleError) {
        developer.log('Failed to reschedule: $rescheduleError', name: 'BackgroundWorker');
      }
      return Future.value(true);
    }
  });
}

/// Clears retry state so the next daily cycle starts at zero.
Future<void> resetDailyWallpaperRetryCount() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_retryCountKey, 0);
}

Future<int> _retryCount() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_retryCountKey) ?? 0;
}

Duration _delayForRetryAttempt(int attempt) {
  switch (attempt) {
    case 1:
      return const Duration(minutes: 15);
    case 2:
      return const Duration(minutes: 30);
    default:
      return const Duration(minutes: 15);
  }
}

Future<void> _scheduleBoundedRetryOrNextDay() async {
  final current = await _retryCount();
  final nextAttempt = current + 1;
  if (nextAttempt > _maxRetries) {
    developer.log(
      'Retry limit reached ($current/$_maxRetries); deferring to next daily schedule',
      name: 'BackgroundWorker',
    );
    await resetDailyWallpaperRetryCount();
    await _rescheduleForNextDay();
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_retryCountKey, nextAttempt);
  final delay = _delayForRetryAttempt(nextAttempt);
  developer.log(
    'Scheduling retry $nextAttempt/$_maxRetries in ${delay.inMinutes} minutes',
    name: 'BackgroundWorker',
  );
  await _registerOneOff(delay);
}

Future<void> _rescheduleForNextDay() async {
  try {
    developer.log('Rescheduling for next day', name: 'BackgroundWorker');
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_scheduledHourKey) ?? 5;
    final minute = prefs.getInt(_scheduledMinuteKey) ?? 0;

    developer.log(
      'Retrieved scheduled time: $hour:${minute.toString().padLeft(2, '0')}',
      name: 'BackgroundWorker',
    );

    // Calculate delay to next occurrence of the scheduled time
    final now = DateTime.now();
    var nextRun = DateTime(now.year, now.month, now.day, hour, minute);

    // If scheduled time has already passed today, schedule for tomorrow
    if (nextRun.isBefore(now)) {
      nextRun = nextRun.add(const Duration(days: 1));
      developer.log(
        'Scheduled time already passed, scheduling for tomorrow at $hour:${minute.toString().padLeft(2, '0')}',
        name: 'BackgroundWorker',
      );
    } else {
      // Schedule for same time tomorrow
      nextRun = nextRun.add(const Duration(days: 1));
      developer.log(
        'Scheduling for tomorrow at $hour:${minute.toString().padLeft(2, '0')}',
        name: 'BackgroundWorker',
      );
    }

    final delay = nextRun.difference(now);
    developer.log(
      'Delay to next execution: ${delay.inMinutes} minutes',
      name: 'BackgroundWorker',
    );

    await _registerOneOff(delay);
    developer.log('Successfully rescheduled task', name: 'BackgroundWorker');
  } catch (e, stackTrace) {
    developer.log('Error rescheduling: $e', name: 'BackgroundWorker', stackTrace: stackTrace);
  }
}

Future<void> _registerOneOff(Duration delay) async {
  await Workmanager().registerOneOffTask(
    dailyVerseUniqueName,
    dailyVerseTask,
    initialDelay: delay,
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
}
