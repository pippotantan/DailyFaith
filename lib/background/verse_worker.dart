import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:zane_bible_lockscreen/core/services/auto_wallpaper_service.dart';

const dailyVerseTask = 'dailyVerseWallpaper';

// Keys must match what SettingsService uses
const _scheduledHourKey = 'daily_scheduled_hour';
const _scheduledMinuteKey = 'daily_scheduled_minute';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Initialize Flutter bindings for background execution
    WidgetsFlutterBinding.ensureInitialized();

    try {
      developer.log('Task received: $task', name: 'BackgroundWorker');
      switch (task) {
        case dailyVerseTask:
          developer.log('Starting AutoWallpaperService.run()', name: 'BackgroundWorker');
          bool success = false;
          try {
            await AutoWallpaperService.run();
            developer.log(
              'AutoWallpaperService.run() completed successfully',
              name: 'BackgroundWorker',
            );
            success = true;
          } catch (e) {
            developer.log('AutoWallpaperService.run() failed: $e', name: 'BackgroundWorker');
            developer.log('Will reschedule for retry in 2 minutes', name: 'BackgroundWorker');
          }

          // Reschedule: if successful, schedule for next day; if failed, retry in 2 minutes
          if (success) {
            await _rescheduleForNextDay();
          } else {
            await _rescheduleForRetry();
          }
          break;
        default:
          developer.log('Unknown task: $task', name: 'BackgroundWorker');
          return Future.value(false); // Unknown task
      }
      return Future.value(true);
    } catch (e, stackTrace) {
      developer.log('Task error: $e', name: 'BackgroundWorker', stackTrace: stackTrace);
      // Try to reschedule for retry in 2 minutes on error
      try {
        await _rescheduleForRetry();
      } catch (rescheduleError) {
        developer.log('Failed to reschedule: $rescheduleError', name: 'BackgroundWorker');
      }
      return Future.value(true);
    }
  });
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

    await Workmanager().registerOneOffTask(
      'dailyVerseTask',
      'dailyVerseWallpaper',
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

    developer.log('Successfully rescheduled task', name: 'BackgroundWorker');
  } catch (e, stackTrace) {
    developer.log('Error rescheduling: $e', name: 'BackgroundWorker', stackTrace: stackTrace);
  }
}

/// Reschedules the wallpaper update task for 2 minutes from now (for transient failures)
Future<void> _rescheduleForRetry() async {
  try {
    developer.log('Rescheduling task for retry in 2 minutes', name: 'BackgroundWorker');

    final delay = const Duration(minutes: 2);

    await Workmanager().registerOneOffTask(
      'dailyVerseTask',
      'dailyVerseWallpaper',
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

    developer.log(
      'Successfully rescheduled task for retry in 2 minutes',
      name: 'BackgroundWorker',
    );
  } catch (e, stackTrace) {
    developer.log(
      'Error rescheduling for retry: $e',
      name: 'BackgroundWorker',
      stackTrace: stackTrace,
    );
  }
}
