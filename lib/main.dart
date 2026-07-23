import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zane_bible_lockscreen/app.dart';
import 'package:workmanager/workmanager.dart';
import 'package:zane_bible_lockscreen/background/verse_worker.dart';
import 'package:zane_bible_lockscreen/core/services/workmanager_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request necessary permissions
  await _requestPermissions();

  await Workmanager().initialize(
    callbackDispatcher,
  );

  // Restore any previously scheduled tasks on app startup
  await _restoreScheduledTasks();

  runApp(const DailyFaithApp());
}

Future<void> _requestPermissions() async {
  try {
    developer.log('Requesting permissions', name: 'Main');

    // Request storage permissions
    final storageStatus = await Permission.storage.request();
    developer.log('Storage permission: $storageStatus', name: 'Main');

    // Request photos/media permission for Android 13+
    final photosStatus = await Permission.photos.request();
    developer.log('Photos permission: $photosStatus', name: 'Main');

    // Request notification permission for Android 13+
    final notificationStatus = await Permission.notification.request();
    developer.log('Notification permission: $notificationStatus', name: 'Main');

    // Request background execution permission
    final scheduleExactAlarmStatus = await Permission.scheduleExactAlarm
        .request();
    developer.log('Schedule exact alarm permission: $scheduleExactAlarmStatus', name: 'Main');

    // Request ignore battery optimizations for reliable background execution
    final batteryOptStatus = await Permission.ignoreBatteryOptimizations
        .request();
    developer.log('Ignore battery optimizations permission: $batteryOptStatus', name: 'Main');

    developer.log('All permissions requested', name: 'Main');
  } catch (e) {
    developer.log('Error requesting permissions: $e', name: 'Main');
  }
}

Future<void> _restoreScheduledTasks() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final isScheduled = prefs.getBool('daily_is_scheduled') ?? false;
    final hour = prefs.getInt('daily_scheduled_hour');
    final minute = prefs.getInt('daily_scheduled_minute');

    if (isScheduled && hour != null && minute != null) {
      developer.log(
        'Restoring scheduled task: $hour:${minute.toString().padLeft(2, '0')}',
        name: 'Main',
      );
      await WorkManagerService.scheduleDailyVerseAt(hour, minute);
      developer.log('Task restored successfully', name: 'Main');
    }
  } catch (e) {
    developer.log('Error restoring tasks: $e', name: 'Main');
  }
}
