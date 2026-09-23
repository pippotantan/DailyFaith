import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zane_bible_lockscreen/features/editor/wallpaper_schedule_section.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:zane_bible_lockscreen/background/daily_verse_work.dart';
import 'package:zane_bible_lockscreen/core/models/wallpaper_schedule.dart';
import 'package:zane_bible_lockscreen/core/services/settings_service.dart';

void main() {
  final mondayAtSix = DateTime(2026, 9, 21, 6, 0);
  final tuesdayAtSix = DateTime(2026, 9, 22, 6, 0);
  final wednesdayMorning = DateTime(2026, 9, 23, 5, 0);
  final wednesdayAfter = DateTime(2026, 9, 23, 10, 0);
  final saturdayAfter = DateTime(2026, 9, 26, 7, 0);

  DateTime? next({
    required DateTime now,
    required Set<int> days,
    int hour = 6,
    int minute = 0,
    bool allowSameMinuteGrace = false,
  }) {
    return ScheduleCalculator.nextOccurrence(
      now: now,
      hour: hour,
      minute: minute,
      daysOfWeek: days,
      allowSameMinuteGrace: allowSameMinuteGrace,
    );
  }

  group('next occurrence', () {
    test('one weekday waits until that day', () {
      expect(
        next(now: wednesdayAfter, days: {DateTime.monday}),
        DateTime(2026, 9, 28, 6, 0),
      );
    });

    test('multiple weekdays skip unselected days', () {
      expect(
        next(now: wednesdayAfter, days: {DateTime.monday, DateTime.tuesday}),
        DateTime(2026, 9, 28, 6, 0),
      );
      expect(
        next(
          now: DateTime(2026, 9, 21, 7, 0),
          days: {DateTime.monday, DateTime.tuesday},
        ),
        tuesdayAtSix,
      );
    });

    test('every day uses the next calendar day after the time has passed', () {
      expect(
        next(now: wednesdayMorning, days: WallpaperSchedule.everyDay),
        DateTime(2026, 9, 23, 6, 0),
      );
      expect(
        next(now: wednesdayAfter, days: WallpaperSchedule.everyDay),
        DateTime(2026, 9, 24, 6, 0),
      );
    });

    test('week rollover from Saturday goes to the next selected weekday', () {
      expect(
        next(now: saturdayAfter, days: {DateTime.monday, DateTime.tuesday}),
        DateTime(2026, 9, 28, 6, 0),
      );
      expect(
        next(now: saturdayAfter, days: WallpaperSchedule.everyDay),
        DateTime(2026, 9, 27, 6, 0),
      );
    });

    test('same-day future occurrence stays on that day', () {
      expect(
        next(
          now: DateTime(2026, 9, 21, 5, 0),
          days: {DateTime.monday, DateTime.tuesday},
        ),
        mondayAtSix,
      );
    });

    test('same-day past occurrence moves to the next configured weekday', () {
      expect(
        next(now: DateTime(2026, 9, 21, 7, 0), days: {DateTime.monday}),
        DateTime(2026, 9, 28, 6, 0),
      );
    });

    test('midnight and day rollover use the civil clock', () {
      expect(
        next(
          now: DateTime(2026, 9, 21, 23, 59),
          days: {DateTime.tuesday},
          hour: 0,
          minute: 0,
        ),
        DateTime(2026, 9, 22, 0, 0),
      );
      expect(
        next(
          now: DateTime(2026, 9, 22, 0, 0),
          days: {DateTime.tuesday},
          hour: 0,
          minute: 0,
        ),
        DateTime(2026, 9, 29, 0, 0),
      );
    });

    test('month and year boundaries keep the configured clock time', () {
      expect(
        next(now: DateTime(2026, 1, 31, 7, 0), days: {DateTime.sunday}),
        DateTime(2026, 2, 1, 6, 0),
      );
      final newYearsEve = DateTime(2026, 12, 31, 8, 0);
      expect(
        next(now: newYearsEve, days: {newYearsEve.weekday}),
        DateTime(2026, 12, 31 + 7, 6, 0),
      );
    });

    test('calendar construction keeps the local hour across a date change', () {
      final now = DateTime(2026, 3, 7, 6, 30);
      final occurrence = next(now: now, days: {DateTime.sunday});
      expect(occurrence, DateTime(2026, 3, 8, 6, 0));
      expect(
        occurrence!.difference(now),
        DateTime(2026, 3, 8, 6, 0).difference(now),
      );
    });

    test(
      'same-minute grace runs soon only when the user just confirmed it',
      () {
        final now = DateTime(2026, 9, 21, 6, 1);
        expect(
          next(now: now, days: {DateTime.monday}, allowSameMinuteGrace: true),
          now.add(ScheduleCalculator.graceRunDelay),
        );
        expect(
          next(now: now, days: {DateTime.monday}),
          DateTime(2026, 9, 28, 6, 0),
        );
      },
    );

    test('empty days and invalid times are rejected', () {
      expect(next(now: wednesdayAfter, days: {}), isNull);
      expect(
        ScheduleCalculator.nextOccurrence(
          now: wednesdayAfter,
          hour: 24,
          minute: 0,
          daysOfWeek: {DateTime.monday},
        ),
        isNull,
      );
      expect(
        const WallpaperSchedule(
          enabled: true,
          hour: 6,
          minute: 0,
          daysOfWeek: {},
        ).validationError,
        'Select at least one day.',
      );
      expect(
        const WallpaperSchedule(
          enabled: false,
          hour: 6,
          minute: 0,
          daysOfWeek: {},
        ).validationError,
        isNull,
      );
    });
  });

  group('day summary', () {
    test('names common combinations from the selected days', () {
      expect(
        WallpaperSchedule.describeDays(WallpaperSchedule.everyDay),
        'Every day',
      );
      expect(
        WallpaperSchedule.describeDays(WallpaperSchedule.weekdays),
        'Weekdays',
      );
      expect(
        WallpaperSchedule.describeDays(WallpaperSchedule.weekends),
        'Weekends',
      );
      expect(WallpaperSchedule.describeDays({DateTime.monday}), 'Every Monday');
      expect(
        WallpaperSchedule.describeDays({DateTime.monday, DateTime.tuesday}),
        'Monday and Tuesday',
      );
      expect(
        WallpaperSchedule.describeDays({DateTime.sunday, DateTime.monday}),
        'Sunday and Monday',
      );
      expect(WallpaperSchedule.describeDays({}), 'No days selected');
    });

    test('upcoming copy does not promise an exact minute', () {
      final text = ScheduleCalculator.describeUpcoming(
        DateTime(2026, 9, 23, 10, 0),
        DateTime(2026, 9, 28, 6, 0),
      );
      expect(text, contains('Monday around 06:00'));
      expect(text, contains('Android may delay it'));
    });
  });

  group('work reconciliation', () {
    final now = DateTime(2026, 9, 23, 10, 0);
    final computed = DateTime(2026, 9, 28, 6, 0);

    test('disabled schedule cancels work', () {
      expect(
        ScheduleReconciler.decide(
          enabled: false,
          hasSelectedDays: true,
          workRunning: false,
          workPending: true,
          storedTarget: computed,
          computedTarget: computed,
          now: now,
        ),
        ScheduleWorkAction.cancel,
      );
    });

    test('empty day selection cancels work', () {
      expect(
        ScheduleReconciler.decide(
          enabled: true,
          hasSelectedDays: false,
          workRunning: false,
          workPending: true,
          storedTarget: computed,
          computedTarget: null,
          now: now,
        ),
        ScheduleWorkAction.cancel,
      );
    });

    test(
      'the same pending target is kept so opening the app does not duplicate work',
      () {
        expect(
          ScheduleReconciler.decide(
            enabled: true,
            hasSelectedDays: true,
            workRunning: false,
            workPending: true,
            storedTarget: computed,
            computedTarget: computed,
            now: now,
          ),
          ScheduleWorkAction.keepExisting,
        );
      },
    );

    test('a changed target replaces the previous job', () {
      expect(
        ScheduleReconciler.decide(
          enabled: true,
          hasSelectedDays: true,
          workRunning: false,
          workPending: true,
          storedTarget: DateTime(2026, 9, 28, 6, 0),
          computedTarget: DateTime(2026, 9, 25, 7, 0),
          now: now,
        ),
        ScheduleWorkAction.replace,
      );
    });

    test('a missing job is registered again', () {
      expect(
        ScheduleReconciler.decide(
          enabled: true,
          hasSelectedDays: true,
          workRunning: false,
          workPending: false,
          storedTarget: computed,
          computedTarget: computed,
          now: now,
        ),
        ScheduleWorkAction.replace,
      );
    });

    test('an overdue queued run is left in place', () {
      expect(
        ScheduleReconciler.decide(
          enabled: true,
          hasSelectedDays: true,
          workRunning: false,
          workPending: true,
          storedTarget: now.subtract(const Duration(minutes: 5)),
          computedTarget: computed,
          now: now,
        ),
        ScheduleWorkAction.keepExisting,
      );
    });

    test('an imminent grace run is not replaced by the following weekday', () {
      expect(
        ScheduleReconciler.decide(
          enabled: true,
          hasSelectedDays: true,
          workRunning: false,
          workPending: true,
          storedTarget: now.add(const Duration(seconds: 20)),
          computedTarget: computed,
          now: now,
        ),
        ScheduleWorkAction.keepExisting,
      );
    });

    test('legacy pending work without a stored target is kept', () {
      expect(
        ScheduleReconciler.decide(
          enabled: true,
          hasSelectedDays: true,
          workRunning: false,
          workPending: true,
          storedTarget: null,
          computedTarget: computed,
          now: now,
        ),
        ScheduleWorkAction.keepExisting,
      );
    });

    test('a running update is not replaced', () {
      expect(
        ScheduleReconciler.decide(
          enabled: true,
          hasSelectedDays: true,
          workRunning: true,
          workPending: true,
          storedTarget: DateTime(2026, 9, 25, 7, 0),
          computedTarget: computed,
          now: now,
        ),
        ScheduleWorkAction.keepExisting,
      );
    });

    test('registration uses one stable unique name and replace policy', () {
      expect(dailyVerseUniqueName, 'dailyVerseTask');
      expect(dailyVerseTask, 'dailyVerseWallpaper');
      expect(dailyVerseExistingWorkPolicy, ExistingWorkPolicy.replace);
    });
  });

  group('persistence', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('saves and restores one time, weekdays, and enabled state', () async {
      const saved = WallpaperSchedule(
        enabled: true,
        hour: 6,
        minute: 0,
        daysOfWeek: {DateTime.monday, DateTime.tuesday},
      );

      await SettingsService.saveWallpaperSchedule(saved);
      final loaded = await SettingsService.loadWallpaperSchedule();

      expect(loaded.enabled, isTrue);
      expect(loaded.hour, 6);
      expect(loaded.minute, 0);
      expect(loaded.daysOfWeek, {DateTime.monday, DateTime.tuesday});
    });

    test('a disabled schedule is restored without turning itself on', () async {
      await SettingsService.saveWallpaperSchedule(
        const WallpaperSchedule(
          enabled: false,
          hour: 7,
          minute: 30,
          daysOfWeek: {DateTime.friday},
        ),
      );

      final loaded = await SettingsService.loadWallpaperSchedule();
      expect(loaded.enabled, isFalse);
      expect(loaded.hour, 7);
      expect(loaded.minute, 30);
      expect(loaded.daysOfWeek, {DateTime.friday});
    });

    test('schedules saved before weekday selection repeat every day', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'daily_is_scheduled': true,
        'daily_scheduled_hour': 5,
        'daily_scheduled_minute': 0,
      });

      final loaded = await SettingsService.loadWallpaperSchedule();
      expect(loaded.enabled, isTrue);
      expect(loaded.hour, 5);
      expect(loaded.daysOfWeek, WallpaperSchedule.everyDay);
    });

    test('changing the saved days replaces the previous selection', () async {
      await SettingsService.saveWallpaperSchedule(
        const WallpaperSchedule(
          enabled: true,
          hour: 6,
          minute: 0,
          daysOfWeek: {DateTime.monday, DateTime.tuesday},
        ),
      );
      await SettingsService.saveWallpaperSchedule(
        const WallpaperSchedule(
          enabled: true,
          hour: 7,
          minute: 0,
          daysOfWeek: {DateTime.friday},
        ),
      );

      final loaded = await SettingsService.loadWallpaperSchedule();
      expect(loaded.daysOfWeek, {DateTime.friday});
      expect(loaded.hour, 7);

      final now = DateTime(2026, 9, 23, 10, 0);
      expect(
        ScheduleCalculator.nextOccurrence(
          now: now,
          hour: loaded.hour,
          minute: loaded.minute,
          daysOfWeek: loaded.daysOfWeek,
        ),
        DateTime(2026, 9, 25, 7, 0),
      );
    });

    test(
      'stores the next target instant independently of the weekdays',
      () async {
        final target = DateTime(2026, 9, 28, 6, 0);
        await SettingsService.setNextScheduledTarget(target);
        expect(await SettingsService.getNextScheduledTarget(), target);
        await SettingsService.setNextScheduledTarget(null);
        expect(await SettingsService.getNextScheduledTarget(), isNull);
      },
    );
  });

  testWidgets('schedule section shows one time and the selected days', (
    tester,
  ) async {
    WallpaperSchedule? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WallpaperScheduleSection(
            schedule: const WallpaperSchedule(
              enabled: true,
              hour: 6,
              minute: 0,
              daysOfWeek: {DateTime.monday},
            ),
            onChanged: (next) async {
              saved = next;
            },
          ),
        ),
      ),
    );

    expect(find.text('Wallpaper Schedule'), findsOneWidget);
    expect(find.text('Every Monday'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(find.byKey(const ValueKey('schedule-day-Monday')), findsOneWidget);
    expect(find.byKey(const ValueKey('schedule-day-Sunday')), findsOneWidget);
    expect(find.byKey(const ValueKey('schedule-day-Saturday')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('schedule-day-Tuesday')));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.enabled, isTrue);
    expect(saved!.hour, 6);
    expect(saved!.minute, 0);
    expect(saved!.daysOfWeek, {DateTime.monday, DateTime.tuesday});
  });

  testWidgets('enabling with no selected days is rejected', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WallpaperScheduleSection(
            schedule: const WallpaperSchedule(
              enabled: false,
              hour: 6,
              minute: 0,
              daysOfWeek: {},
            ),
            onChanged: (next) async {
              calls += 1;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(calls, 0);
    expect(find.text('Select at least one day.'), findsOneWidget);
  });
}
