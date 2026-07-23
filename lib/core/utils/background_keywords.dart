/// Background image filter for Pexels. Default "all" uses a varied query.
/// Other keywords are passed as the Pexels API `query` for /v1/search.
class BackgroundKeywords {
  static const String all = 'all';

  static const List<String> keywordIds = [
    all,
    'nature',
    'christian',
    'animals',
    'wildlife',
    'outer space',
    'landscape',
    'sky',
    'ocean',
    'mountains',
    'flowers',
  ];

  /// Display label for settings UI.
  static String labelFor(String id) {
    switch (id) {
      case all:
        return 'All (varied)';
      case 'nature':
        return 'Nature';
      case 'christian':
        return 'Christian';
      case 'animals':
        return 'Animals';
      case 'wildlife':
        return 'Wildlife';
      case 'outer space':
        return 'Outer Space';
      case 'landscape':
        return 'Landscape';
      case 'sky':
        return 'Sky';
      case 'ocean':
        return 'Ocean';
      case 'mountains':
        return 'Mountains';
      case 'flowers':
        return 'Flowers';
      default:
        return id;
    }
  }

  /// Pexels API query string. For "all" returns a broad default query.
  static String queryFor(String id) {
    if (id == all || id.isEmpty) {
      return 'nature';
    }
    return id;
  }
}
