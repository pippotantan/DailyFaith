import 'dart:convert';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/bible_verse.dart';
import '../utils/bible_topics.dart';

class BibleApiService {
  static const String baseUrl =
      'https://labs.bible.org/api/?type=json&passage=';

  static const int _maxRetries = 5;
  static const Duration _timeout = Duration(seconds: 30);
  static const Duration _initialBackoff = Duration(seconds: 2);

  /// [topicId] optional; e.g. "all" (default), "love", "hope". When not "all", picks from that topic's passages.
  Future<BibleVerse> fetchRandomVerse({String? topicId}) async {
    final passage = BibleTopics.getRandomPassageForTopic(topicId);
    final formatted = passage.replaceAll(' ', '+');
    final url = Uri.parse('$baseUrl$formatted');

    developer.log(
      'Fetching verse: $passage (topic: ${topicId ?? "all"})',
      name: 'BibleApiService',
    );

    return _retryWithBackoff(
      () => _fetchVerseWithTimeout(url),
      maxAttempts: _maxRetries,
    );
  }

  Future<BibleVerse> _fetchVerseWithTimeout(Uri url) async {
    try {
      developer.log('Making HTTP request to: $url', name: 'BibleApiService');

      final response = await http
          .get(url)
          .timeout(
            _timeout,
            onTimeout: () {
              throw TimeoutException(
                'Bible API request timed out after ${_timeout.inSeconds}s',
                _timeout,
              );
            },
          );

      developer.log('Response status: ${response.statusCode}', name: 'BibleApiService');

      if (response.statusCode != 200 || response.body.isEmpty) {
        throw Exception('Bible API returned status ${response.statusCode}');
      }

      final List data = jsonDecode(response.body);
      if (data.isEmpty) {
        throw Exception('Bible API returned empty data list');
      }

      final verse = data.first;

      final rawText = (verse['text'] as String).trim();

      return BibleVerse(
        reference: '${verse['bookname']} ${verse['chapter']}:${verse['verse']}',
        text: rawText,
      );
    } catch (e) {
      developer.log('Error: $e', name: 'BibleApiService');
      rethrow;
    }
  }

  Future<T> _retryWithBackoff<T>(
    Future<T> Function() operation, {
    required int maxAttempts,
  }) async {
    Duration backoff = _initialBackoff;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        developer.log('Attempt $attempt/$maxAttempts', name: 'BibleApiService');
        return await operation();
      } catch (e) {
        developer.log('Attempt $attempt failed: $e', name: 'BibleApiService');

        if (attempt == maxAttempts) {
          developer.log('All retries exhausted', name: 'BibleApiService');
          rethrow;
        }

        developer.log('Retrying in ${backoff.inSeconds}s...', name: 'BibleApiService');
        await Future.delayed(backoff);

        // Exponential backoff: 2s, 4s, 8s
        backoff = Duration(seconds: backoff.inSeconds * 2);
      }
    }

    throw Exception('Unexpected error in retry logic');
  }
}
