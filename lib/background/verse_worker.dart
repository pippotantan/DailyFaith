import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import 'package:zane_bible_lockscreen/background/daily_verse_work.dart';
import 'package:zane_bible_lockscreen/core/services/auto_wallpaper_service.dart';
import 'package:zane_bible_lockscreen/core/services/settings_service.dart';
import 'package:zane_bible_lockscreen/core/services/workmanager_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      developer.log('Task received: $task', name: 'DailyFaithSchedule');
      switch (task) {
        case dailyVerseTask:
          developer.log(
            'Starting AutoWallpaperService.run()',
            name: 'DailyFaithSchedule',
          );
          bool success = false;
          try {
            await AutoWallpaperService.run();
            developer.log(
              'AutoWallpaperService.run() completed successfully',
              name: 'DailyFaithSchedule',
            );
            success = true;
          } catch (e) {
            developer.log(
              'AutoWallpaperService.run() failed: $e',
              name: 'DailyFaithSchedule',
            );
          }

          if (success) {
            await resetDailyWallpaperRetryCount();
            await WorkManagerService.rescheduleFromPersistedConfig();
          } else {
            await _scheduleBoundedRetryOrNextDay();
          }
          break;
        default:
          developer.log('Unknown task: $task', name: 'BackgroundWorker');
          return false;
      }
      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Task error: $e',
        name: 'BackgroundWorker',
        stackTrace: stackTrace,
      );
      try {
        await _scheduleBoundedRetryOrNextDay();
      } catch (rescheduleError) {
        developer.log(
          'Failed to reschedule: $rescheduleError',
          name: 'BackgroundWorker',
        );
      }
      return true;
    }
  });
}

Future<void> _scheduleBoundedRetryOrNextDay() async {
  final schedule = await SettingsService.loadWallpaperSchedule();
  if (!schedule.enabled || schedule.validationError != null) {
    developer.log('Schedule is off; skipping retry', name: 'BackgroundWorker');
    await resetDailyWallpaperRetryCount();
    await SettingsService.setNextScheduledTarget(null);
    return;
  }

  final current = await readDailyWallpaperRetryCount();
  final nextAttempt = current + 1;
  if (nextAttempt > dailyWallpaperMaxRetries) {
    developer.log(
      'Retry limit reached ($current/$dailyWallpaperMaxRetries); '
      'deferring to the next selected weekday',
      name: 'BackgroundWorker',
    );
    await resetDailyWallpaperRetryCount();
    await WorkManagerService.rescheduleFromPersistedConfig();
    return;
  }

  await setDailyWallpaperRetryCount(nextAttempt);
  final delay = delayForWallpaperRetryAttempt(nextAttempt);
  developer.log(
    'Scheduling retry $nextAttempt/$dailyWallpaperMaxRetries '
    'in ${delay.inMinutes} minutes',
    name: 'BackgroundWorker',
  );
  await WorkManagerService.enqueueRetry(delay);
}
