import 'dart:math';
import 'bible_metadata.dart';

/// Topic/keyword filter for verse selection. Default "all" = all 66 books.
/// Theme topics use curated passage lists. Book keywords pick any verse from
/// that book (Corinthians includes both letters).
class BibleTopics {
  static const String all = 'all';

  static const List<String> topicIds = [
    all,
    'love',
    'strength',
    'hope',
    'peace',
    'faith',
    'comfort',
    'wisdom',
    'grace',
    'joy',
    'psalms',
    'proverbs',
    'ecclesiastes',
    'song of solomon',
    'job',
    'matthew',
    'mark',
    'luke',
    'john',
    'acts',
    'romans',
    'corinthians',
    'galatians',
    'ephesians',
    'philippians',
    'isaiah',
    'jeremiah',
    'ezekiel',
    'daniel',
    'revelation',
  ];

  /// Display label for each topic (for settings UI).
  static String labelFor(String topicId) {
    switch (topicId) {
      case all:
        return 'All (66 books)';
      case 'love':
        return 'Love';
      case 'strength':
        return 'Strength';
      case 'hope':
        return 'Hope';
      case 'peace':
        return 'Peace';
      case 'faith':
        return 'Faith';
      case 'comfort':
        return 'Comfort';
      case 'wisdom':
        return 'Wisdom';
      case 'grace':
        return 'Grace';
      case 'joy':
        return 'Joy';
      case 'psalms':
        return 'Psalms';
      case 'proverbs':
        return 'Proverbs';
      case 'ecclesiastes':
        return 'Ecclesiastes';
      case 'song of solomon':
        return 'Song of Solomon';
      case 'job':
        return 'Job';
      case 'matthew':
        return 'Matthew';
      case 'mark':
        return 'Mark';
      case 'luke':
        return 'Luke';
      case 'john':
        return 'John';
      case 'acts':
        return 'Acts';
      case 'romans':
        return 'Romans';
      case 'corinthians':
        return 'Corinthians';
      case 'galatians':
        return 'Galatians';
      case 'ephesians':
        return 'Ephesians';
      case 'philippians':
        return 'Philippians';
      case 'isaiah':
        return 'Isaiah';
      case 'jeremiah':
        return 'Jeremiah';
      case 'ezekiel':
        return 'Ezekiel';
      case 'daniel':
        return 'Daniel';
      case 'revelation':
        return 'Revelation';
      default:
        return topicId;
    }
  }

  /// Books a keyword draws from. Corinthians includes both letters.
  static const Map<String, List<String>> booksByTopic = {
    'psalms': ['Psalms'],
    'proverbs': ['Proverbs'],
    'ecclesiastes': ['Ecclesiastes'],
    'song of solomon': ['Song of Solomon'],
    'job': ['Job'],
    'matthew': ['Matthew'],
    'mark': ['Mark'],
    'luke': ['Luke'],
    'john': ['John'],
    'acts': ['Acts'],
    'romans': ['Romans'],
    'corinthians': ['1 Corinthians', '2 Corinthians'],
    'galatians': ['Galatians'],
    'ephesians': ['Ephesians'],
    'philippians': ['Philippians'],
    'isaiah': ['Isaiah'],
    'jeremiah': ['Jeremiah'],
    'ezekiel': ['Ezekiel'],
    'daniel': ['Daniel'],
    'revelation': ['Revelation'],
  };

  /// True when [reference] is a verse from one of [topicId]'s books.
  static bool referenceMatchesTopic(String reference, String topicId) {
    final books = booksByTopic[topicId];
    if (books == null) return false;
    for (final book in books) {
      final names = book == 'Psalms' ? const ['Psalm', 'Psalms'] : [book];
      for (final name in names) {
        if (reference.startsWith('$name ')) return true;
      }
    }
    return false;
  }

  /// Curated passages per topic (single verse refs for labs.bible.org API).
  static final Map<String, List<String>> _passagesByTopic = {
    'love': [
      'John 3:16',
      '1 Corinthians 13:4',
      '1 John 4:8',
      'Romans 8:38',
      'John 13:34',
      '1 John 4:19',
      'Romans 5:8',
      '1 John 4:7',
      'John 15:12',
      'Ephesians 4:2',
    ],
    'strength': [
      'Isaiah 40:31',
      'Philippians 4:13',
      'Psalm 46:1',
      'Nehemiah 8:10',
      'Psalm 27:1',
      '2 Samuel 22:33',
      'Isaiah 41:10',
      'Psalm 18:32',
      'Exodus 15:2',
      'Isaiah 12:2',
    ],
    'hope': [
      'Jeremiah 29:11',
      'Romans 15:13',
      'Hebrews 6:19',
      'Psalm 42:5',
      'Romans 5:5',
      'Lamentations 3:24',
      'Psalm 71:14',
      'Isaiah 40:31',
      'Hebrews 11:1',
      'Psalm 130:5',
    ],
    'peace': [
      'John 14:27',
      'Philippians 4:7',
      'Isaiah 26:3',
      'Romans 5:1',
      'Colossians 3:15',
      'Isaiah 54:10',
      'Matthew 5:9',
      'Psalm 29:11',
      '2 Thessalonians 3:16',
      'John 16:33',
    ],
    'faith': [
      'Hebrews 11:1',
      'Matthew 17:20',
      'Romans 1:17',
      'Ephesians 2:8',
      'James 2:17',
      'Mark 9:23',
      'Galatians 2:20',
      'Hebrews 11:6',
      'Romans 10:17',
      'Matthew 21:22',
    ],
    'comfort': [
      'Psalm 23:4',
      '2 Corinthians 1:3',
      'Matthew 5:4',
      'Isaiah 41:10',
      'Psalm 34:18',
      'Isaiah 49:13',
      'Psalm 119:76',
      '2 Thessalonians 2:16',
      'John 14:18',
      'Psalm 94:19',
    ],
    'wisdom': [
      'Proverbs 3:5',
      'James 1:5',
      'Proverbs 2:6',
      'Proverbs 4:7',
      'Colossians 2:3',
      'Proverbs 9:10',
      'James 3:17',
      'Proverbs 16:16',
      'Ecclesiastes 7:12',
      'Proverbs 19:8',
    ],
    'grace': [
      'Ephesians 2:8',
      '2 Corinthians 12:9',
      'Titus 2:11',
      'Hebrews 4:16',
      'John 1:16',
      'Romans 3:24',
      'James 4:6',
      '1 Peter 5:10',
      'Romans 5:20',
      '2 Timothy 2:1',
    ],
    'joy': [
      'Nehemiah 8:10',
      'Psalm 16:11',
      'John 15:11',
      'James 1:2',
      'Galatians 5:22',
      'Romans 15:13',
      'Psalm 126:3',
      'Isaiah 55:12',
      'Luke 2:10',
      '1 Peter 1:8',
    ],
  };

  static final Random _random = Random();

  /// Returns a random passage reference. If [topicId] is null, "all", or unknown,
  /// uses all 66 books via BibleMetadata.randomPassage(). A book keyword picks
  /// any verse from that book. Other topics use a curated list.
  static String getRandomPassageForTopic(String? topicId) {
    if (topicId == null || topicId.isEmpty || topicId == all) {
      return BibleMetadata.randomPassage();
    }
    final books = booksByTopic[topicId];
    if (books != null && books.isNotEmpty) {
      final book = books[_random.nextInt(books.length)];
      return BibleMetadata.randomPassageFrom(book);
    }
    final list = _passagesByTopic[topicId];
    if (list == null || list.isEmpty) {
      return BibleMetadata.randomPassage();
    }
    return list[_random.nextInt(list.length)];
  }
}
