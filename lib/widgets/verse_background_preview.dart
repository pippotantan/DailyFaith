import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:zane_bible_lockscreen/core/models/verse_text_position.dart';
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
  final VerseTextPosition position;

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
    this.position = VerseTextPosition.legacy,
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
        imageWidget,
        Container(color: Colors.black.withValues(alpha: 0.48)),
        LayoutBuilder(
          builder: (context, constraints) {
            final canvas = Size(constraints.maxWidth, constraints.maxHeight);
            final placement = measureVerseBlock(
              canvas: canvas,
              verse: verse,
              reference: reference,
              verseStyle: verseBaseStyle,
              referenceStyle: referenceStyle,
              textAlign: textAlign,
              position: position,
              gap: 24,
            );
            return Stack(
              children: [
                Positioned(
                  left: placement.rect.left,
                  top: placement.rect.top,
                  width: placement.rect.width,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                      Text(
                        reference,
                        textAlign: textAlign,
                        style: referenceStyle,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class VerseBlockPlacement {
  const VerseBlockPlacement({
    required this.rect,
    required this.inkWidth,
    required this.blockHeight,
  });

  final Rect rect;
  final double inkWidth;
  final double blockHeight;
}

/// Measures the verse block and places it with [VerseTextLayout].
///
/// The preview and the drag control both use this so a saved fraction lands
/// on the same part of the image as the wallpaper generator.
VerseBlockPlacement measureVerseBlock({
  required Size canvas,
  required String verse,
  required String reference,
  required TextStyle verseStyle,
  required TextStyle referenceStyle,
  required TextAlign textAlign,
  required VerseTextPosition position,
  required double gap,
}) {
  final maxWidth =
      canvas.width *
      (1 -
          (2 *
              VerseTextLayout.horizontalPadding /
              VerseTextLayout.referenceWidth));
  final layoutWidth = position.width == null
      ? maxWidth
      : VerseTextLayout.containerWidth(canvas, position.width!);
  final versePainter = TextPainter(
    text: TextSpan(text: plainVerseText(verse), style: verseStyle),
    textAlign: textAlign,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: layoutWidth);
  final referencePainter = TextPainter(
    text: TextSpan(text: reference, style: referenceStyle),
    textAlign: textAlign,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: layoutWidth);

  final inkWidth = math.max(
    _longestLine(versePainter),
    _longestLine(referencePainter),
  );
  final blockHeight = versePainter.height + gap + referencePainter.height;
  final blockWidth = position.width != null
      ? layoutWidth
      : inkWidth.clamp(1.0, maxWidth);
  final rect = position.isCustom
      ? VerseTextLayout.placeBlock(
          canvas: canvas,
          block: Size(blockWidth, blockHeight),
          anchor: Offset(position.x, position.y),
          margin: VerseTextLayout.marginFor(canvas),
        )
      : VerseTextLayout.legacyBlockRect(
          canvas: canvas,
          blockHeight: blockHeight,
        );
  return VerseBlockPlacement(
    rect: rect,
    inkWidth: inkWidth,
    blockHeight: blockHeight,
  );
}

double _longestLine(TextPainter painter) {
  final metrics = painter.computeLineMetrics();
  if (metrics.isEmpty) return painter.width;
  return metrics.map((line) => line.width).reduce(math.max);
}
