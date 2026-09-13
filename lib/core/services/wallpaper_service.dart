import 'dart:io';

import 'package:flutter/services.dart';

class WallpaperService {
  static const _channel =
      MethodChannel('com.example.zane_bible_lockscreen/wallpaper');

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
