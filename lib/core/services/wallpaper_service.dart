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
  }) async {
    final ok = await _channel.invokeMethod<bool>(
      'setWallpaper',
      {
        'path': imageFile.path,
        'location': location,
      },
    );
    if (ok != true) {
      throw PlatformException(
        code: 'WALLPAPER_ERROR',
        message: 'Failed to set wallpaper',
      );
    }
  }
}
