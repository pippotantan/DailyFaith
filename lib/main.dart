import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zane_bible_lockscreen/app.dart';
import 'package:workmanager/workmanager.dart';
import 'package:zane_bible_lockscreen/background/verse_worker.dart';
import 'package:zane_bible_lockscreen/core/services/workmanager_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Workmanager().initialize(
    callbackDispatcher,
  );

  // Restore any previously scheduled tasks on app startup
  await _restoreScheduledTasks();

  runApp(const DailyFaithApp());
}

Future<void> _restoreScheduledTasks() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final isScheduled = prefs.getBool('daily_is_scheduled') ?? false;
    final hour = prefs.getInt('daily_scheduled_hour');
    final minute = prefs.getInt('daily_scheduled_minute');

    if (isScheduled && hour != null && minute != null) {
      final pending = await Workmanager().isScheduledByUniqueName(
        dailyVerseUniqueName,
      );
      if (pending) {
        developer.log(
          'Pending daily work already exists; not replacing on launch',
          name: 'DailyFaithSchedule',
        );
        return;
      }
      developer.log(
        'Restoring scheduled task: $hour:${minute.toString().padLeft(2, '0')}',
        name: 'DailyFaithSchedule',
      );
      await WorkManagerService.scheduleDailyVerseAt(hour, minute);
      developer.log('Task restored successfully', name: 'DailyFaithSchedule');
    }
  } catch (e) {
    developer.log('Error restoring tasks: $e', name: 'Main');
  }
}
