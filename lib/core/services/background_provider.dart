import 'package:zane_bible_lockscreen/core/models/background_result.dart';
import 'package:zane_bible_lockscreen/core/models/background_source.dart';
import 'package:zane_bible_lockscreen/core/services/local_gallery_service.dart';
import 'package:zane_bible_lockscreen/core/services/network_service.dart';
import 'package:zane_bible_lockscreen/core/services/settings_service.dart';
import 'package:zane_bible_lockscreen/core/services/pexels_service.dart';

/// Unified provider for background images.
/// Selects between Pexels and local gallery based on user settings.
/// When offline, falls back to local gallery if available.
class BackgroundProvider {
  /// Fetches a background image based on current settings.
  /// - If [BackgroundSource.localGallery]: returns random local image (works offline).
  /// - If [BackgroundSource.pexels]: uses Pexels when online; falls back to local gallery when offline.
  static Future<BackgroundResult?> fetchBackground({
    required String keywordId,
  }) async {
    final source = await SettingsService.getBackgroundSource();

    switch (source) {
      case BackgroundSource.localGallery:
        final path = await LocalGalleryService.getRandomPath();
        if (path != null) {
          return BackgroundResult(localPath: path);
        }
        // No local images: try Pexels as fallback when online
        if (await NetworkService.hasNetworkConnection()) {
          try {
            final result = await PexelsService().fetchRandomBackground(
              keywordId: keywordId,
            );
            return BackgroundResult(
              imageUrl: result.imageUrl,
              attributionText: result.attributionText,
            );
          } catch (_) {}
        }
        return null;

      case BackgroundSource.pexels:
        final hasNetwork = await NetworkService.hasNetworkConnection();
        if (hasNetwork) {
          try {
            final result = await PexelsService().fetchRandomBackground(
              keywordId: keywordId,
            );
            return BackgroundResult(
              imageUrl: result.imageUrl,
              attributionText: result.attributionText,
            );
          } catch (e) {
            print('[BackgroundProvider] Pexels failed, trying local: $e');
          }
        }
        // Offline or Pexels failed: fallback to local gallery
        final path = await LocalGalleryService.getRandomPath();
        if (path != null) {
          return BackgroundResult(localPath: path);
        }
        return null;
    }
  }
}
