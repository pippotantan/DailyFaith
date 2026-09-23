import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Normalized anchor for the verse block on a wallpaper.
///
/// [x] and [y] are fractions of the wallpaper width and height, from the
/// top-left. They locate the **center** of the verse block (verse plus
/// reference), not its top-left corner. Text alignment is separate: it aligns
/// lines inside that block and does not change [x] or [y].
///
/// [isCustom] is false when the user has never moved the verse. Rendering then
/// keeps the historical centered layout, so existing wallpapers stay the same.
///
/// [width] is the verse container width as a fraction of the wallpaper width.
/// Null keeps the automatic width: the historical column, or the text's own
/// width after a move.
class VerseTextPosition {
  const VerseTextPosition({
    required this.x,
    required this.y,
    this.width,
    this.isCustom = true,
  });

  /// Centered layout used before this setting existed.
  static const legacy = VerseTextPosition(x: 0.5, y: 0.5, isCustom: false);

  final double x;
  final double y;
  final double? width;
  final bool isCustom;

  VerseTextPosition copyWith({
    double? x,
    double? y,
    double? width,
    bool clearWidth = false,
    bool? isCustom,
  }) {
    return VerseTextPosition(
      x: x ?? this.x,
      y: y ?? this.y,
      width: clearWidth ? null : (width ?? this.width),
      isCustom: isCustom ?? this.isCustom,
    );
  }
}

/// Shared placement for the preview and the generated wallpaper.
///
/// Coordinates are normalized, then converted to the canvas being drawn.
/// A 1080×1920 wallpaper and a smaller preview use the same fractions.
class VerseTextLayout {
  VerseTextLayout._();

  /// Wallpaper canvas the generator still draws. Home/lock fitting is separate.
  static const referenceWidth = 1080.0;
  static const referenceHeight = 1920.0;

  /// Insets of the historical centered text column.
  static const horizontalPadding = 172.0;
  static const verticalPadding = 230.0;

  /// Logical width the in-app font size is authored against.
  static const previewReferenceWidth = 400.0;

  /// Minimum gap between the verse block and the wallpaper edge.
  static const edgeMargin = 24.0;

  /// Narrowest container, as a fraction of the wallpaper width.
  static const minWidthFraction = 0.18;

  static double marginFor(Size canvas) {
    return canvas.width * (edgeMargin / referenceWidth);
  }

  /// Container width in pixels for a normalized [fraction] of [canvas].
  static double containerWidth(Size canvas, double fraction) {
    final margin = marginFor(canvas);
    final maxWidth = math.max(1.0, canvas.width - (2 * margin));
    final minWidth = math.min(maxWidth, canvas.width * minWidthFraction);
    final requested = fraction.isFinite ? fraction * canvas.width : maxWidth;
    return requested.clamp(minWidth, maxWidth);
  }

  /// Historical content column: horizontally centered with the existing
  /// padding, vertically centered, and kept inside the vertical padding.
  static Rect legacyBlockRect({
    required Size canvas,
    required double blockHeight,
  }) {
    final left = canvas.width * (horizontalPadding / referenceWidth);
    final width = canvas.width - (2 * left);
    final verticalInset = canvas.height * (verticalPadding / referenceHeight);
    final centered = (canvas.height - blockHeight) / 2;
    final maxTop = canvas.height - verticalInset - blockHeight;
    final top = maxTop >= verticalInset
        ? centered.clamp(verticalInset, maxTop)
        : verticalInset;
    return Rect.fromLTWH(left, top, width, blockHeight);
  }

  /// Centers [block] on [anchor], then shifts it so the block stays inside
  /// [canvas] by [margin]. The anchor is the block center, not its top-left.
  static Rect placeBlock({
    required Size canvas,
    required Size block,
    required Offset anchor,
    double margin = edgeMargin,
  }) {
    final marginX = margin.clamp(0.0, canvas.width / 2).toDouble();
    final marginY = margin.clamp(0.0, canvas.height / 2).toDouble();
    final minLeft = marginX;
    final maxLeft = math.max(minLeft, canvas.width - marginX - block.width);
    final minTop = marginY;
    final maxTop = math.max(minTop, canvas.height - marginY - block.height);
    final left = (anchor.dx * canvas.width - block.width / 2).clamp(
      minLeft,
      maxLeft,
    );
    final top = (anchor.dy * canvas.height - block.height / 2).clamp(
      minTop,
      maxTop,
    );
    return Rect.fromLTWH(left, top, block.width, block.height);
  }

  /// Normalized center of a placed block. This is the value to persist.
  static Offset anchorOf(Rect rect, Size canvas) {
    return Offset(
      (rect.left + rect.width / 2) / canvas.width,
      (rect.top + rect.height / 2) / canvas.height,
    );
  }

  /// Left edge of the visible glyphs inside a wider layout box.
  ///
  /// Alignment does not move the stored anchor. It only changes where the
  /// lines sit inside the box, which is how the centered default keeps
  /// left-aligned and right-aligned verses where they are today.
  static double inkLeft({
    required double boxLeft,
    required double layoutWidth,
    required double inkWidth,
    required TextAlign align,
  }) {
    switch (align) {
      case TextAlign.left:
      case TextAlign.start:
        return boxLeft;
      case TextAlign.right:
      case TextAlign.end:
        return boxLeft + layoutWidth - inkWidth;
      case TextAlign.center:
      case TextAlign.justify:
        return boxLeft + (layoutWidth - inkWidth) / 2;
    }
  }
}
