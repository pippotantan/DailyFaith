import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:zane_bible_lockscreen/core/config/app_channels.dart';

class WallpaperService {
  static const _channel = MethodChannel(AppChannels.wallpaper);

  static const String lockScreen = 'lockScreen';
  static const String homeScreen = 'homeScreen';
  static const String both = 'both';

  static Future<void> setWallpaper(
    File imageFile, {
    String location = both,
    bool fitHomeToDisplay = false,
  }) async {
    developer.log(
      'Invoking setWallpaper location=$location fitHomeToDisplay=$fitHomeToDisplay path=${imageFile.path}',
      name: 'DailyFaithWallpaper',
    );
    try {
      final ok = await _channel.invokeMethod<bool>(
        'setWallpaper',
        {
          'path': imageFile.path,
          'location': location,
          'fitHomeToDisplay': fitHomeToDisplay,
        },
      );
      if (ok != true) {
        throw PlatformException(
          code: 'WALLPAPER_ERROR',
          message: 'Failed to set wallpaper',
        );
      }
    } on MissingPluginException catch (e, stackTrace) {
      developer.log(
        'Wallpaper MethodChannel is not registered on this engine: $e',
        name: 'DailyFaithWallpaper',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
