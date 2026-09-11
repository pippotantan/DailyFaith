import 'dart:developer' as developer;

import 'package:zane_bible_lockscreen/core/data/offline_verses.dart';
import 'package:zane_bible_lockscreen/core/models/bible_verse.dart';
import 'package:zane_bible_lockscreen/core/services/bible_api_service.dart';
import 'package:zane_bible_lockscreen/core/services/network_service.dart';

/// Unified verse source: tries API when online, falls back to offline store.
/// Ensures verse display works with or without internet.
class VerseRepository {
  final BibleApiService _api = BibleApiService();

  /// Fetches a random verse for the given topic.
  /// When online: tries API first, falls back to offline if API fails.
  /// When offline: uses pre-loaded verses from OfflineVerses.
  Future<BibleVerse> fetchRandomVerse({String? topicId}) async {
    final hasNetwork = await NetworkService.hasNetworkConnection();

    if (hasNetwork) {
      try {
        final verse = await _api.fetchRandomVerse(topicId: topicId);
        return verse;
      } catch (e) {
        developer.log('API failed, using offline: $e', name: 'VerseRepository');
      }
    } else {
      developer.log('Offline: using pre-loaded verses', name: 'VerseRepository');
    }

    final offline = OfflineVerses.getRandomVerse(topicId);
    if (offline != null) {
      return BibleVerse(
        reference: offline['reference']!,
        text: offline['text']!,
      );
    }

    throw Exception(
      'No verse available. Please check your connection or try again.',
    );
  }
}
