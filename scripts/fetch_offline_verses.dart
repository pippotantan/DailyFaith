// Run with: dart run scripts/fetch_offline_verses.dart
// Fetches verse text from labs.bible.org and outputs JSON for assets/data/offline_verses.json

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:http/http.dart' as http;

const passages = {
  'love': [
    'John 3:16', '1 Corinthians 13:4', '1 John 4:8', 'Romans 8:38',
    'John 13:34', '1 John 4:19', 'Romans 5:8', '1 John 4:7',
    'John 15:12', 'Ephesians 4:2',
  ],
  'strength': [
    'Isaiah 40:31', 'Philippians 4:13', 'Psalm 46:1', 'Nehemiah 8:10',
    'Psalm 27:1', '2 Samuel 22:33', 'Isaiah 41:10', 'Psalm 18:32',
    'Exodus 15:2', 'Isaiah 12:2',
  ],
  'hope': [
    'Jeremiah 29:11', 'Romans 15:13', 'Hebrews 6:19', 'Psalm 42:5',
    'Romans 5:5', 'Lamentations 3:24', 'Psalm 71:14', 'Isaiah 40:31',
    'Hebrews 11:1', 'Psalm 130:5',
  ],
  'peace': [
    'John 14:27', 'Philippians 4:7', 'Isaiah 26:3', 'Romans 5:1',
    'Colossians 3:15', 'Isaiah 54:10', 'Matthew 5:9', 'Psalm 29:11',
    '2 Thessalonians 3:16', 'John 16:33',
  ],
  'faith': [
    'Hebrews 11:1', 'Matthew 17:20', 'Romans 1:17', 'Ephesians 2:8',
    'James 2:17', 'Mark 9:23', 'Galatians 2:20', 'Hebrews 11:6',
    'Romans 10:17', 'Matthew 21:22',
  ],
  'comfort': [
    'Psalm 23:4', '2 Corinthians 1:3', 'Matthew 5:4', 'Isaiah 41:10',
    'Psalm 34:18', 'Isaiah 49:13', 'Psalm 119:76', '2 Thessalonians 2:16',
    'John 14:18', 'Psalm 94:19',
  ],
  'wisdom': [
    'Proverbs 3:5', 'James 1:5', 'Proverbs 2:6', 'Proverbs 4:7',
    'Colossians 2:3', 'Proverbs 9:10', 'James 3:17', 'Proverbs 16:16',
    'Ecclesiastes 7:12', 'Proverbs 19:8',
  ],
  'grace': [
    'Ephesians 2:8', '2 Corinthians 12:9', 'Titus 2:11', 'Hebrews 4:16',
    'John 1:16', 'Romans 3:24', 'James 4:6', '1 Peter 5:10',
    'Romans 5:20', '2 Timothy 2:1',
  ],
  'joy': [
    'Nehemiah 8:10', 'Psalm 16:11', 'John 15:11', 'James 1:2',
    'Galatians 5:22', 'Romans 15:13', 'Psalm 126:3', 'Isaiah 55:12',
    'Luke 2:10', '1 Peter 1:8',
  ],
};

const allPassages = [
  'John 3:16', 'Psalm 23:1', 'Philippians 4:13', 'Proverbs 3:5',
  'Romans 8:28', 'Matthew 11:28', 'Isaiah 41:10', 'Psalm 46:1',
  'Jeremiah 29:11', 'Romans 12:2', 'Joshua 1:9', 'Psalm 27:1',
  '2 Timothy 1:7', 'Isaiah 40:31', 'Psalm 121:1', 'Matthew 6:33',
  'Romans 8:38', 'Psalm 34:4', 'Hebrews 11:1', 'John 14:27',
  'Psalm 119:105', 'Isaiah 43:2', 'Romans 15:13', 'Psalm 37:4',
  'Matthew 28:20', 'Psalm 91:1', 'Proverbs 16:3', 'John 16:33',
  'Psalm 139:14', 'Romans 10:9', 'Isaiah 26:3', 'Psalm 32:8',
  'Matthew 5:14', 'Colossians 3:2', 'Psalm 19:14', 'John 1:12',
  'Romans 5:8', 'Psalm 118:24', 'Isaiah 55:8', 'Matthew 6:34',
  'Psalm 56:3', 'Romans 8:1', 'Proverbs 22:6', 'John 8:12',
  'Psalm 103:12', 'Isaiah 40:8', 'Matthew 7:7', 'Romans 12:12',
  'Psalm 27:14', 'John 10:10', 'Philippians 4:6', 'Psalm 31:24',
  'Isaiah 54:10', 'Matthew 11:29', 'Romans 8:31', 'Psalm 18:2',
  'Proverbs 3:6', 'John 15:5', 'Psalm 23:4', 'Romans 8:37',
  'Isaiah 43:19', 'Matthew 17:20', 'Psalm 34:18', 'John 14:6',
  'Romans 12:1', 'Psalm 91:11', 'Proverbs 4:23', 'Isaiah 40:29',
  'Matthew 5:16', 'Romans 8:39', 'Psalm 37:5', 'John 6:35',
  'Psalm 121:7', 'Isaiah 55:6', 'Matthew 28:19', 'Romans 10:13',
  'Psalm 46:10', 'Proverbs 16:9', 'John 11:25', 'Psalm 27:1',
  'Romans 5:5', 'Isaiah 43:1', 'Matthew 6:9', 'Psalm 34:8',
  'John 3:17', 'Romans 12:10', 'Psalm 119:11', 'Isaiah 26:4',
  'Matthew 5:44', 'Romans 8:28', 'Psalm 23:6', 'Proverbs 3:3',
  'John 4:24', 'Psalm 118:6', 'Isaiah 41:13', 'Matthew 7:12',
];

void main() async {
  final result = <String, List<Map<String, String>>>{};

  for (final entry in passages.entries) {
    result[entry.key] = [];
    for (final ref in entry.value) {
      final v = await fetchVerse(ref);
      if (v != null) result[entry.key]!.add(v);
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  result['all'] = [];
  for (final ref in allPassages) {
    final v = await fetchVerse(ref);
    if (v != null) result['all']!.add(v);
    await Future.delayed(const Duration(milliseconds: 200));
  }

  final file = File('assets/data/offline_verses.json');
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(result),
  );
  developer.log(
    'Wrote ${result.values.fold<int>(0, (a, b) => a + b.length)} verses to ${file.path}',
    name: 'fetch_offline_verses',
  );
}

Future<Map<String, String>?> fetchVerse(String passage) async {
  try {
    final url = Uri.parse(
      'https://labs.bible.org/api/?type=json&passage=${Uri.encodeComponent(passage.replaceAll(' ', '+'))}',
    );
    final resp = await http.get(url).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return null;
    final data = jsonDecode(resp.body) as List;
    if (data.isEmpty) return null;
    final v = data.first as Map<String, dynamic>;
    return {
      'reference': '${v['bookname']} ${v['chapter']}:${v['verse']}',
      'text': v['text'] as String,
    };
  } catch (e) {
    developer.log('Failed $passage: $e', name: 'fetch_offline_verses');
    return null;
  }
}
