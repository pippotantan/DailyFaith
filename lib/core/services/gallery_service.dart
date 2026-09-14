import 'package:flutter/services.dart';
import 'package:zane_bible_lockscreen/core/config/app_channels.dart';

class GalleryService {
  static const _channel = MethodChannel(AppChannels.wallpaper);

  static Future<Map<dynamic, dynamic>> saveImage(
    Uint8List bytes, {
    required String name,
    int quality = 100,
  }) async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'saveImageToGallery',
      {
        'imageBytes': bytes,
        'name': name,
        'quality': quality,
      },
    );
    return result ?? {'isSuccess': false, 'error': 'No result from platform'};
  }
}
