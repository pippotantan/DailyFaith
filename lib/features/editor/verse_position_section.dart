import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:zane_bible_lockscreen/core/models/verse_text_position.dart';
import 'package:zane_bible_lockscreen/core/utils/verse_text_parser.dart';
import 'package:zane_bible_lockscreen/core/utils/verse_text_style.dart';
import 'package:zane_bible_lockscreen/widgets/verse_background_preview.dart';

/// Drag surface for the verse block. The gesture stays on the verse, so the
/// rest of the editor can still scroll.
class VersePositionSection extends StatefulWidget {
  const VersePositionSection({
    super.key,
    required this.verse,
    required this.reference,
    required this.fontSize,
    required this.textAlign,
    required this.textColor,
    required this.fontFamily,
    required this.position,
    this.imageUrl,
    this.localPath,
    required this.onPositionChanged,
    required this.onPositionCommitted,
  });

  final String verse;
  final String reference;
  final double fontSize;
  final TextAlign textAlign;
  final Color textColor;
  final String fontFamily;
  final VerseTextPosition position;
  final String? imageUrl;
  final String? localPath;
  final ValueChanged<VerseTextPosition> onPositionChanged;
  final ValueChanged<VerseTextPosition> onPositionCommitted;

  @override
  State<VersePositionSection> createState() => _VersePositionSectionState();
}

class _VersePositionSectionState extends State<VersePositionSection> {
  VerseTextPosition? _dragging;
  var _moved = false;
  double? _resizeWidthPx;
  double? _pinLeft;
  double? _pinTop;

  VerseTextPosition get _shown => _dragging ?? widget.position;

  @override
  void didUpdateWidget(covariant VersePositionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dragging == null) return;
    if (!widget.position.isCustom && oldWidget.position.isCustom) {
      _clearGesture();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Verse Position',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            const maxHeight = 300.0;
            var width = constraints.maxWidth;
            var height =
                width *
                VerseTextLayout.referenceHeight /
                VerseTextLayout.referenceWidth;
            if (height > maxHeight) {
              height = maxHeight;
              width =
                  height *
                  VerseTextLayout.referenceWidth /
                  VerseTextLayout.referenceHeight;
            }
            return Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: _PositionPad(
                      verse: widget.verse,
                      reference: widget.reference,
                      fontSize: widget.fontSize,
                      textAlign: widget.textAlign,
                      textColor: widget.textColor,
                      fontFamily: widget.fontFamily,
                      position: _shown,
                      imageUrl: widget.imageUrl,
                      localPath: widget.localPath,
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      onResizeStart: _onResizeStart,
                      onResizeUpdate: _onResizeUpdate,
                      onResizeEnd: _onPanEnd,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        const Text(
          'Drag the verse to move it. Drag the corner to resize.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.center,
          child: TextButton(
            onPressed:
                widget.position.isCustom ||
                    widget.position.width != null ||
                    _dragging != null
                ? () {
                    setState(_clearGesture);
                    widget.onPositionCommitted(VerseTextPosition.legacy);
                  }
                : null,
            child: const Text('Reset position'),
          ),
        ),
      ],
    );
  }

  void _onPanStart(VerseTextPosition origin) {
    _moved = false;
    _dragging = origin;
  }

  void _onPanUpdate(Offset delta, Size canvas, Size block) {
    final base = _dragging;
    if (base == null) return;
    final moved = Offset(
      base.x + delta.dx / canvas.width,
      base.y + delta.dy / canvas.height,
    );
    final placed = VerseTextLayout.placeBlock(
      canvas: canvas,
      block: block,
      anchor: moved,
      margin: VerseTextLayout.marginFor(canvas),
    );
    final anchor = VerseTextLayout.anchorOf(placed, canvas);
    final next = VerseTextPosition(
      x: anchor.dx,
      y: anchor.dy,
      width: base.width,
    );
    _moved = true;
    setState(() => _dragging = next);
    widget.onPositionChanged(next);
  }

  void _onResizeStart(Rect rect) {
    _moved = false;
    _resizeWidthPx = rect.width;
    _pinLeft = rect.left;
    _pinTop = rect.top;
    _dragging = _shown;
  }

  void _onResizeUpdate(
    Offset delta,
    Size canvas,
    double Function(double widthPx) heightFor,
  ) {
    final startWidth = _resizeWidthPx;
    final pinLeft = _pinLeft;
    final pinTop = _pinTop;
    if (startWidth == null || pinLeft == null || pinTop == null) return;

    final margin = VerseTextLayout.marginFor(canvas);
    final maxWidth = math.max(1.0, canvas.width - (2 * margin));
    final minWidth = math.min(
      maxWidth,
      canvas.width * VerseTextLayout.minWidthFraction,
    );
    final available = math.max(minWidth, canvas.width - margin - pinLeft);
    final nextWidth = (startWidth + delta.dx)
        .clamp(minWidth, math.min(maxWidth, available))
        .toDouble();
    _resizeWidthPx = nextWidth;

    final height = heightFor(nextWidth);
    var top = pinTop;
    final bottomLimit = canvas.height - margin;
    if (top + height > bottomLimit) {
      top = math.max(margin, bottomLimit - height);
    }
    if (top < margin) top = margin;
    final left = math.max(margin, pinLeft);
    final anchor = VerseTextLayout.anchorOf(
      Rect.fromLTWH(left, top, nextWidth, height),
      canvas,
    );
    final next = VerseTextPosition(
      x: anchor.dx,
      y: anchor.dy,
      width: nextWidth / canvas.width,
    );
    _moved = true;
    setState(() => _dragging = next);
    widget.onPositionChanged(next);
  }

  void _onPanEnd() {
    final dropped = _dragging;
    if (_moved && dropped != null) {
      widget.onPositionCommitted(dropped);
    }
    setState(_clearGesture);
  }

  void _clearGesture() {
    _dragging = null;
    _moved = false;
    _resizeWidthPx = null;
    _pinLeft = null;
    _pinTop = null;
  }
}

class _PositionPad extends StatelessWidget {
  const _PositionPad({
    required this.verse,
    required this.reference,
    required this.fontSize,
    required this.textAlign,
    required this.textColor,
    required this.fontFamily,
    required this.position,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onResizeStart,
    required this.onResizeUpdate,
    required this.onResizeEnd,
    this.imageUrl,
    this.localPath,
  });

  final String verse;
  final String reference;
  final double fontSize;
  final TextAlign textAlign;
  final Color textColor;
  final String fontFamily;
  final VerseTextPosition position;
  final String? imageUrl;
  final String? localPath;
  final ValueChanged<VerseTextPosition> onPanStart;
  final void Function(Offset delta, Size canvas, Size block) onPanUpdate;
  final VoidCallback onPanEnd;
  final ValueChanged<Rect> onResizeStart;
  final void Function(
    Offset delta,
    Size canvas,
    double Function(double widthPx) heightFor,
  )
  onResizeUpdate;
  final VoidCallback onResizeEnd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvas = Size(constraints.maxWidth, constraints.maxHeight);
        final scale = canvas.width / VerseTextLayout.previewReferenceWidth;
        final verseStyle = TextStyle(
          fontSize: fontSize * scale,
          color: textColor,
          height: 1.3,
          fontFamily: fontFamily,
          fontWeight: FontWeight.w500,
          shadows: VerseTextStyle.readabilityShadows(),
        );
        final referenceStyle = TextStyle(
          fontSize: fontSize * 0.55 * scale,
          color: textColor.withValues(alpha: 0.9),
          fontStyle: FontStyle.italic,
          fontFamily: 'Roboto',
          shadows: VerseTextStyle.readabilityShadows(),
        );
        final gap = 24.0 * scale;
        final placement = measureVerseBlock(
          canvas: canvas,
          verse: verse,
          reference: reference,
          verseStyle: verseStyle,
          referenceStyle: referenceStyle,
          textAlign: textAlign,
          position: position,
          gap: gap,
        );
        final block = Size(
          position.isCustom
              ? placement.rect.width
              : math.max(
                  1.0,
                  placement.inkWidth.clamp(1, placement.rect.width),
                ),
          placement.blockHeight,
        );
        return Stack(
          children: [
            _PadBackground(imageUrl: imageUrl, localPath: localPath),
            Container(color: Colors.black.withValues(alpha: 0.48)),
            Positioned(
              left: placement.rect.left - 12,
              top: placement.rect.top - 12,
              width: placement.rect.width + 24,
              child: GestureDetector(
                key: const ValueKey('verse-position-pad'),
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) {
                  onPanStart(_origin(canvas, placement, block));
                },
                onPanUpdate: (details) {
                  onPanUpdate(details.delta, canvas, block);
                },
                onPanEnd: (_) => onPanEnd(),
                onPanCancel: onPanEnd,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RichText(
                        textAlign: textAlign,
                        text: TextSpan(
                          style: verseStyle,
                          children: buildVerseTextSpans(
                            raw: verse,
                            baseStyle: verseStyle,
                          ),
                        ),
                      ),
                      SizedBox(height: gap),
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
            Positioned.fromRect(
              rect: placement.rect,
              child: const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: placement.rect.right - 14,
              top: placement.rect.bottom - 14,
              width: 28,
              height: 28,
              child: GestureDetector(
                key: const ValueKey('verse-resize-handle'),
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) => onResizeStart(placement.rect),
                onPanUpdate: (details) {
                  onResizeUpdate(details.delta, canvas, (widthPx) {
                    return measureVerseBlock(
                      canvas: canvas,
                      verse: verse,
                      reference: reference,
                      verseStyle: verseStyle,
                      referenceStyle: referenceStyle,
                      textAlign: textAlign,
                      position: position.copyWith(
                        width: widthPx / canvas.width,
                        isCustom: true,
                      ),
                      gap: gap,
                    ).blockHeight;
                  });
                },
                onPanEnd: (_) => onResizeEnd(),
                onPanCancel: onResizeEnd,
                child: const Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black54, blurRadius: 2),
                      ],
                    ),
                    child: SizedBox(width: 16, height: 16),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Center of the visible text. For the historical layout this is the ink
  /// center, so the first drag does not jump left-aligned or right-aligned text.
  VerseTextPosition _origin(
    Size canvas,
    VerseBlockPlacement placement,
    Size block,
  ) {
    if (position.isCustom) {
      return position;
    }
    final inkLeft = VerseTextLayout.inkLeft(
      boxLeft: placement.rect.left,
      layoutWidth: placement.rect.width,
      inkWidth: block.width,
      align: textAlign,
    );
    final anchor = VerseTextLayout.anchorOf(
      Rect.fromLTWH(inkLeft, placement.rect.top, block.width, block.height),
      canvas,
    );
    return VerseTextPosition(x: anchor.dx, y: anchor.dy);
  }
}

class _PadBackground extends StatelessWidget {
  const _PadBackground({this.imageUrl, this.localPath});

  final String? imageUrl;
  final String? localPath;

  @override
  Widget build(BuildContext context) {
    if (localPath != null && localPath!.isNotEmpty) {
      return Image.file(
        File(localPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return const ColoredBox(color: Color(0xFF1a1a2e));
  }
}
