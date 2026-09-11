import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Shared readability styling for verse text on dark photo overlays.
class VerseTextStyle {
  VerseTextStyle._();

  /// Dark outline shadows — verse text always renders on a 48% black overlay.
  static List<Shadow> readabilityShadows() {
    return [
      Shadow(
        color: Colors.black.withValues(alpha: 0.9),
        offset: const Offset(2, 2),
        blurRadius: 2,
      ),
      Shadow(
        color: Colors.black.withValues(alpha: 0.6),
        offset: const Offset(1, 1),
        blurRadius: 4,
      ),
    ];
  }

  /// Canvas shadow color matching [readabilityShadows] for wallpaper generation.
  static ui.Color canvasShadowColor() {
    return const ui.Color(0xE6000000);
  }
}
