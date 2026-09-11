import 'package:flutter_test/flutter_test.dart';
import 'package:zane_bible_lockscreen/core/utils/verse_text_parser.dart';

void main() {
  group('parseVerseText', () {
    test('returns plain segment when no tags present', () {
      final segments = parseVerseText('For God so loved the world.');
      expect(segments, [const VerseTextSegment('For God so loved the world.')]);
    });

    test('parses single bold tag', () {
      final segments = parseVerseText(
        'just as it is written, "<b>The righteous by faith will live</b>."',
      );
      expect(segments.length, 3);
      expect(segments[0].text, 'just as it is written, "');
      expect(segments[0].isBold, isFalse);
      expect(segments[1].text, 'The righteous by faith will live');
      expect(segments[1].isBold, isTrue);
      expect(segments[2].text, '."');
      expect(segments[2].isBold, isFalse);
    });

    test('parses adjacent bold tags', () {
      final segments = parseVerseText(
        'For <b>everyone</b><b> who calls on the name of the Lord will be saved</b>.',
      );
      expect(segments.length, 4);
      expect(segments[0].text, 'For ');
      expect(segments[1].text, 'everyone');
      expect(segments[1].isBold, isTrue);
      expect(segments[2].text, ' who calls on the name of the Lord will be saved');
      expect(segments[2].isBold, isTrue);
      expect(segments[3].text, '.');
      expect(segments[3].isBold, isFalse);
    });

    test('strips unknown tags from plain segments', () {
      final segments = parseVerseText('Hello <i>world</i> today');
      expect(segments, [const VerseTextSegment('Hello world today')]);
    });
  });

  group('plainVerseText', () {
    test('removes bold tags and keeps text', () {
      expect(
        plainVerseText('"<b>The righteous by faith will live</b>."'),
        '"The righteous by faith will live."',
      );
    });
  });
}
