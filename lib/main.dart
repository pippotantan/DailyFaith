import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:zane_bible_lockscreen/app.dart';
import 'package:workmanager/workmanager.dart';
import 'package:zane_bible_lockscreen/background/verse_worker.dart';
import 'package:zane_bible_lockscreen/core/services/workmanager_service.dart';

final _scheduleRestore = _WallpaperScheduleRestore();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Workmanager().initialize(callbackDispatcher);

  // Reloads the saved weekly schedule after process start, including the
  // first open after Android force-stop clears WorkManager jobs.
  WidgetsBinding.instance.addObserver(_scheduleRestore);
  await _restoreScheduledTasks();

  runApp(const DailyFaithApp());
}

Future<void> _restoreScheduledTasks() async {
  try {
    await WorkManagerService.reconcilePersistedSchedule();
  } catch (e) {
    developer.log('Error restoring tasks: $e', name: 'Main');
  }
}

/// Recomputes the next local weekday time when the app returns to the
/// foreground, so a clock or timezone change is picked up without a second job.
class _WallpaperScheduleRestore extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WorkManagerService.reconcilePersistedSchedule();
    }
  }
}
