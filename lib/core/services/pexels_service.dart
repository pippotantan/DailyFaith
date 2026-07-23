import 'dart:convert';
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:http/http.dart' as http;
import '../utils/background_keywords.dart';

/// Result of a random Pexels photo.
/// Attribution text follows Pexels guidelines: "Photo by [Name] on Pexels".
class PexelsPhotoResult {
  final String imageUrl;
  final String attributionText;

  const PexelsPhotoResult({
    required this.imageUrl,
    required this.attributionText,
  });
}

class PexelsService {
  static const String _apiKey =
      '49usv2qBrCsJUchqA3tay3SL5NgSzSOAI5gPRO5uW8wjRHgV4HH9RMNk';

  static const String _searchUrl = 'https://api.pexels.com/v1/search';

  static const int _maxRetries = 5;
  static const Duration _timeout = Duration(seconds: 30);
  static const Duration _initialBackoff = Duration(seconds: 2);
  static const int _perPage = 15;

  static const List<String> _variedQueries = [
    'nature',
    'faith',
    'sky',
    'landscape',
    'flowers',
    'mountains',
  ];

  final Random _random = Random();

  /// Fetches a random background. [keywordId] filters by Pexels search query.
  Future<PexelsPhotoResult> fetchRandomBackground({String? keywordId}) async {
    developer.log(
      'Fetching random background image (keyword: ${keywordId ?? "all"})',
      name: 'PexelsService',
    );

    return _retryWithBackoff(
      () => _fetchPhotoWithTimeout(keywordId),
      maxAttempts: _maxRetries,
    );
  }

  Future<PexelsPhotoResult> _fetchPhotoWithTimeout(String? keywordId) async {
    try {
      final query = _queryFor(keywordId ?? BackgroundKeywords.all);
      final page = 1 + _random.nextInt(10);
      final endpoint =
          '$_searchUrl?query=${Uri.encodeQueryComponent(query)}&orientation=portrait&per_page=$_perPage&page=$page';
      developer.log('Making HTTP request to Pexels API', name: 'PexelsService');

      final response = await http
          .get(
            Uri.parse(endpoint),
            headers: {'Authorization': _apiKey},
          )
          .timeout(
            _timeout,
            onTimeout: () {
              throw TimeoutException(
                'Pexels API request timed out after ${_timeout.inSeconds}s',
                _timeout,
              );
            },
          );

      developer.log('Response status: ${response.statusCode}', name: 'PexelsService');

      if (response.statusCode != 200 || response.body.isEmpty) {
        throw Exception('Pexels API returned status ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final photos = data['photos'] as List<dynamic>? ?? [];

      if (photos.isEmpty) {
        throw Exception('Pexels response contained no photos for query: $query');
      }

      final photo = photos[_random.nextInt(photos.length)] as Map<String, dynamic>;
      final src = photo['src'] as Map<String, dynamic>?;
      final imageUrl = _bestImageUrl(src);

      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception('Pexels response missing image URL in photo.src');
      }

      final name = photo['photographer'] as String? ?? 'Unknown';
      final attributionText = 'Photo by $name on Pexels';

      developer.log(
        'Image URL: ${imageUrl.substring(0, imageUrl.length > 50 ? 50 : imageUrl.length)}...',
        name: 'PexelsService',
      );
      return PexelsPhotoResult(
        imageUrl: imageUrl,
        attributionText: attributionText,
      );
    } catch (e) {
      developer.log('Error: $e', name: 'PexelsService');
      rethrow;
    }
  }

  String _queryFor(String keywordId) {
    if (keywordId == BackgroundKeywords.all || keywordId.isEmpty) {
      return _variedQueries[_random.nextInt(_variedQueries.length)];
    }
    return BackgroundKeywords.queryFor(keywordId);
  }

  String? _bestImageUrl(Map<String, dynamic>? src) {
    if (src == null) return null;
    return src['large2x'] as String? ??
        src['large'] as String? ??
        src['portrait'] as String? ??
        src['original'] as String?;
  }

  Future<T> _retryWithBackoff<T>(
    Future<T> Function() operation, {
    required int maxAttempts,
  }) async {
    Duration backoff = _initialBackoff;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        developer.log('Attempt $attempt/$maxAttempts', name: 'PexelsService');
        return await operation();
      } catch (e) {
        developer.log('Attempt $attempt failed: $e', name: 'PexelsService');

        if (attempt == maxAttempts) {
          developer.log('All retries exhausted', name: 'PexelsService');
          rethrow;
        }

        developer.log('Retrying in ${backoff.inSeconds}s...', name: 'PexelsService');
        await Future.delayed(backoff);

        backoff = Duration(seconds: backoff.inSeconds * 2);
      }
    }

    throw Exception('Unexpected error in retry logic');
  }
}
