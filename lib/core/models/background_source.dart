/// Source of background images for verse wallpapers.
/// [pexels] uses the Pexels API (requires internet).
/// [localGallery] uses user-selected images from device gallery (works offline).
enum BackgroundSource {
  pexels,
  localGallery,
}

extension BackgroundSourceExtension on BackgroundSource {
  String get displayName {
    switch (this) {
      case BackgroundSource.pexels:
        return 'Pexels (online)';
      case BackgroundSource.localGallery:
        return 'Device gallery (offline)';
    }
  }
}
