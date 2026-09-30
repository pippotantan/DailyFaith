/// Background image filter for Pexels. Default "all" picks one of [searchKeywords].
/// Other keywords are passed as the Pexels API `query` for /v1/search.
class BackgroundKeywords {
  static const String all = 'all';

  static const List<String> searchKeywords = [
    'jesus & saints',
    'abstract background',
    'textured wallpaper',
    'neutral flatlay',
    'minimalist texture',
    'beige watercolor',
    'fine linen',
    'calm sea morning',
    'misty forest dawn',
    'soft sun rays',
    'foggy mountain sunrise',
    'dark rocky cliff',
    'moody mountain peak',
    'deep ocean wave',
    'desert canyon',
    'wildflower macro',
    'eucalyptus leaves',
    'sun flare trees',
    'bokeh light background',
    'animals',
    'wildlife',
    'outer space',
  ];

  static const List<String> keywordIds = [all, ...searchKeywords];

  /// Display label for settings UI.
  static String labelFor(String id) {
    if (id == all) return 'All (varied)';
    return id
        .split(' ')
        .map((word) {
          if (word.isEmpty || word == '&') return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }
}
