import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zane_bible_lockscreen/core/utils/verse_text_parser.dart';
import 'package:zane_bible_lockscreen/core/utils/verse_text_style.dart';

class VerseBackgroundPreview extends StatelessWidget {
  /// Network image URL (from Pexels). Use when [localPath] is null.
  final String? imageUrl;

  /// Local file path (from device gallery). Use when [localPath] is null.
  final String? localPath;

  final String verse;
  final String reference;
  final double fontSize;
  final TextAlign textAlign;
  final Color textColor;
  final String fontFamily;

  const VerseBackgroundPreview({
    super.key,
    this.imageUrl,
    this.localPath,
    required this.verse,
    required this.reference,
    required this.fontSize,
    required this.textAlign,
    required this.textColor,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (localPath != null && localPath!.isNotEmpty) {
      imageWidget = Image.file(File(localPath!), fit: BoxFit.cover);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageWidget = Image.network(imageUrl!, fit: BoxFit.cover);
    } else {
      imageWidget = Container(color: const Color(0xFF1a1a2e));
    }

    final verseBaseStyle = TextStyle(
      fontSize: fontSize,
      color: textColor,
      height: 1.3,
      fontFamily: fontFamily,
      fontWeight: FontWeight.w500,
      shadows: VerseTextStyle.readabilityShadows(),
    );

    final referenceStyle = TextStyle(
      fontSize: fontSize * 0.55,
      color: textColor.withValues(alpha: 0.9),
      fontStyle: FontStyle.italic,
      fontFamily: 'Roboto',
      shadows: VerseTextStyle.readabilityShadows(),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        /// Background
        imageWidget,

        /// Dark overlay for readability on any background
        Container(color: Colors.black.withValues(alpha: 0.48)),

        /// Safe padded content (generous so text is never cut off)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 56),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Verse (shadow for readability on any background)
                  RichText(
                    textAlign: textAlign,
                    text: TextSpan(
                      style: verseBaseStyle,
                      children: buildVerseTextSpans(
                        raw: verse,
                        baseStyle: verseBaseStyle,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// Reference (smaller + simple font, shadow for readability)
                  Text(
                    reference,
                    textAlign: textAlign,
                    style: referenceStyle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
