import 'dart:developer' as developer;

import 'package:workmanager/workmanager.dart';
import 'package:zane_bible_lockscreen/background/daily_verse_work.dart';
import 'package:zane_bible_lockscreen/core/models/wallpaper_schedule.dart';
import 'package:zane_bible_lockscreen/core/services/settings_service.dart';

/// Schedules wallpaper updates with one inexact WorkManager job.
///
/// The saved schedule is one time of day plus the selected weekdays. A periodic
/// worker cannot express that: WorkManager periods are interval-based, at least
/// 15 minutes, and are not tied to a weekday clock time. This service instead
/// enqueues the next occurrence only. After the worker runs, it enqueues the
/// following selected weekday. [ExistingWorkPolicy.replace] on
/// [dailyVerseUniqueName] keeps a single job.
///
/// Timing is not exact. Android may defer the job.
class WorkManagerService {
  static Future<void> scheduleDailyVerse() async {
    await SettingsService.saveWallpaperSchedule(
      WallpaperSchedule.initial.copyWith(enabled: true),
    );
    await enqueueConfigured(allowSameMinuteGrace: false);
  }

  static Future<void> cancelDailyVerse() async {
    developer.log('Cancelling daily verse task', name: 'WorkManagerService');
    await Workmanager().cancelByUniqueName(dailyVerseUniqueName);
    await resetDailyWallpaperRetryCount();
    await SettingsService.setNextScheduledTarget(null);
    developer.log('Daily verse task cancelled', name: 'WorkManagerService');
  }

  /// Enqueues the next run from the persisted schedule.
  ///
  /// [allowSameMinuteGrace] is only for a user confirming the current minute
  /// in the time picker. Restores and post-run scheduling leave it false so a
  /// finished run cannot immediately schedule itself again.
  static Future<String> enqueueConfigured({
    required bool allowSameMinuteGrace,
    bool cancelExisting = true,
  }) async {
    final schedule = await SettingsService.loadWallpaperSchedule();
    final error = schedule.validationError;
    if (!schedule.enabled || error != null) {
      throw StateError(error ?? 'Schedule is off');
    }

    final now = DateTime.now();
    final target = ScheduleCalculator.nextOccurrence(
      now: now,
      hour: schedule.hour,
      minute: schedule.minute,
      daysOfWeek: schedule.daysOfWeek,
      allowSameMinuteGrace: allowSameMinuteGrace,
    );
    if (target == null) {
      throw StateError('Select at least one day.');
    }

    if (cancelExisting) {
      await cancelDailyVerse();
    }

    final delay = target.difference(now);
    developer.log(
      'Registering wallpaper work in ${delay.inSeconds}s for '
      '${target.weekday} ${target.hour}:${target.minute.toString().padLeft(2, '0')}',
      name: 'DailyFaithSchedule',
    );
    await registerDailyVerseWork(
      delay: delay,
      target: target,
      rememberTarget: true,
    );
    return ScheduleCalculator.describeUpcoming(now, target);
  }

  /// After a successful run, queue the following selected weekday.
  static Future<void> rescheduleFromPersistedConfig() async {
    try {
      final schedule = await SettingsService.loadWallpaperSchedule();
      if (!schedule.enabled || schedule.validationError != null) {
        developer.log(
          'Schedule is off; not queueing another wallpaper update',
          name: 'BackgroundWorker',
        );
        await SettingsService.setNextScheduledTarget(null);
        return;
      }
      await enqueueConfigured(
        allowSameMinuteGrace: false,
        cancelExisting: false,
      );
      developer.log(
        'Queued the next selected weekday',
        name: 'BackgroundWorker',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error rescheduling: $e',
        name: 'BackgroundWorker',
        stackTrace: stackTrace,
      );
    }
  }

  /// Keeps a failed run on a short retry without moving the saved weekday target.
  static Future<void> enqueueRetry(Duration delay) async {
    final target = DateTime.now().add(delay);
    developer.log(
      'Scheduling wallpaper retry in ${delay.inMinutes} minutes',
      name: 'BackgroundWorker',
    );
    await registerDailyVerseWork(
      delay: delay,
      target: target,
      rememberTarget: false,
    );
  }

  /// Reloads the saved schedule and aligns the single WorkManager job with it.
  ///
  /// Force-stop clears WorkManager jobs until the app is opened again. This
  /// registers a replacement only when the saved schedule is enabled and no
  /// matching job is already pending. It does not bypass force-stop.
  static Future<void> reconcilePersistedSchedule() async {
    try {
      final schedule = await SettingsService.loadWallpaperSchedule();
      final now = DateTime.now();
      final computed = ScheduleCalculator.nextOccurrence(
        now: now,
        hour: schedule.hour,
        minute: schedule.minute,
        daysOfWeek: schedule.daysOfWeek,
      );
      WorkInfo? info;
      try {
        info = await Workmanager().getWorkInfo(dailyVerseUniqueName);
      } catch (e) {
        developer.log(
          'Work status unavailable: $e',
          name: 'DailyFaithSchedule',
        );
      }
      final stored = await SettingsService.getNextScheduledTarget();
      final action = ScheduleReconciler.decide(
        enabled: schedule.enabled,
        hasSelectedDays:
            schedule.daysOfWeek.isNotEmpty && schedule.validationError == null,
        workRunning: info?.state == WorkState.running,
        workPending: info?.state == WorkState.scheduled,
        storedTarget: stored,
        computedTarget: computed,
        now: now,
      );

      switch (action) {
        case ScheduleWorkAction.keepExisting:
          developer.log(
            'Pending wallpaper work already matches the saved schedule',
            name: 'DailyFaithSchedule',
          );
          return;
        case ScheduleWorkAction.cancel:
          final active =
              info?.state == WorkState.scheduled ||
              info?.state == WorkState.running;
          if (active || stored != null) {
            await cancelDailyVerse();
          }
          return;
        case ScheduleWorkAction.replace:
          developer.log(
            'Registering wallpaper work from the saved schedule',
            name: 'DailyFaithSchedule',
          );
          await enqueueConfigured(allowSameMinuteGrace: false);
          return;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error restoring schedule: $e',
        name: 'DailyFaithSchedule',
        stackTrace: stackTrace,
      );
    }
  }
}
