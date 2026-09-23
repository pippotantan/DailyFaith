import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:zane_bible_lockscreen/core/services/settings_service.dart';

const dailyVerseTask = 'dailyVerseWallpaper';
const dailyVerseUniqueName = 'dailyVerseTask';

/// One unique WorkManager job. [ExistingWorkPolicy.replace] drops the previous
/// registration instead of stacking another wallpaper update.
const dailyVerseExistingWorkPolicy = ExistingWorkPolicy.replace;

const dailyWallpaperRetryCountKey = 'daily_wallpaper_retry_count';
const dailyWallpaperMaxRetries = 3;

Future<void> resetDailyWallpaperRetryCount() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(dailyWallpaperRetryCountKey, 0);
}

Future<int> readDailyWallpaperRetryCount() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(dailyWallpaperRetryCountKey) ?? 0;
}

Future<void> setDailyWallpaperRetryCount(int value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(dailyWallpaperRetryCountKey, value);
}

Duration delayForWallpaperRetryAttempt(int attempt) {
  switch (attempt) {
    case 1:
      return const Duration(minutes: 15);
    case 2:
      return const Duration(minutes: 30);
    default:
      return const Duration(minutes: 15);
  }
}

/// Registers the single inexact wallpaper job.
///
/// WorkManager may run this later than [delay] because of Doze, app standby,
/// and OEM power limits. This does not use exact alarms or a foreground service.
Future<void> registerDailyVerseWork({
  required Duration delay,
  required DateTime target,
  required bool rememberTarget,
}) async {
  final safeDelay = delay.isNegative ? Duration.zero : delay;
  if (rememberTarget) {
    await SettingsService.setNextScheduledTarget(target);
  }
  await Workmanager().registerOneOffTask(
    dailyVerseUniqueName,
    dailyVerseTask,
    initialDelay: safeDelay,
    constraints: Constraints(
      networkType: NetworkType.notRequired,
      requiresBatteryNotLow: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
    ),
    backoffPolicy: BackoffPolicy.exponential,
    backoffPolicyDelay: const Duration(minutes: 15),
    existingWorkPolicy: dailyVerseExistingWorkPolicy,
  );
}
