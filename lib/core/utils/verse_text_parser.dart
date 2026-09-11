import 'package:flutter/material.dart';

/// A segment of verse text with optional bold formatting.
class VerseTextSegment {
  final String text;
  final bool isBold;

  const VerseTextSegment(this.text, {this.isBold = false});

  @override
  bool operator ==(Object other) {
    return other is VerseTextSegment &&
        other.text == text &&
        other.isBold == isBold;
  }

  @override
  int get hashCode => Object.hash(text, isBold);
}

/// Parses labs.bible.org verse text, rendering `<b>` tags as bold segments.
List<VerseTextSegment> parseVerseText(String raw) {
  final segments = <VerseTextSegment>[];
  final boldPattern = RegExp(r'<b>(.*?)</b>', dotAll: true);
  var lastEnd = 0;

  for (final match in boldPattern.allMatches(raw)) {
    if (match.start > lastEnd) {
      final plain = _stripUnknownTags(raw.substring(lastEnd, match.start));
      if (plain.isNotEmpty) {
        segments.add(VerseTextSegment(plain));
      }
    }

    final boldText = match.group(1)!;
    if (boldText.isNotEmpty) {
      segments.add(VerseTextSegment(boldText, isBold: true));
    }
    lastEnd = match.end;
  }

  if (lastEnd < raw.length) {
    final plain = _stripUnknownTags(raw.substring(lastEnd));
    if (plain.isNotEmpty) {
      segments.add(VerseTextSegment(plain));
    }
  }

  if (segments.isEmpty && raw.isNotEmpty) {
    segments.add(VerseTextSegment(_stripUnknownTags(raw)));
  }

  return segments;
}

/// Returns verse text with all HTML tags removed.
String plainVerseText(String raw) {
  return parseVerseText(raw).map((segment) => segment.text).join();
}

String _stripUnknownTags(String text) {
  return text.replaceAll(RegExp(r'<[^>]*>'), '');
}

/// Builds [TextSpan] children for in-app verse preview.
List<TextSpan> buildVerseTextSpans({
  required String raw,
  required TextStyle baseStyle,
}) {
  final segments = parseVerseText(raw);
  return segments
      .map(
        (segment) => TextSpan(
          text: segment.text,
          style: segment.isBold
              ? baseStyle.copyWith(fontWeight: FontWeight.w700)
              : baseStyle,
        ),
      )
      .toList();
}
