/// Unified result for background image retrieval.
/// Either [imageUrl] (from Pexels) or [localPath] (from device gallery) will be set.
class BackgroundResult {
  /// URL for network image (Pexels). Null when using local gallery.
  final String? imageUrl;

  /// Local file path for device gallery image. Null when using Pexels.
  final String? localPath;

  /// Attribution text (e.g. "Photo by X on Pexels"). Only for Pexels.
  final String? attributionText;

  const BackgroundResult({
    this.imageUrl,
    this.localPath,
    this.attributionText,
  });

  bool get isLocal => localPath != null && localPath!.isNotEmpty;
  bool get isNetwork => imageUrl != null && imageUrl!.isNotEmpty;
}
