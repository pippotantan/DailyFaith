import 'package:flutter/material.dart';
import 'package:zane_bible_lockscreen/core/models/verse_text_position.dart';
import 'package:zane_bible_lockscreen/core/models/wallpaper_schedule.dart';
import 'package:zane_bible_lockscreen/features/editor/verse_position_section.dart';
import 'package:zane_bible_lockscreen/features/editor/wallpaper_schedule_section.dart';
import 'package:zane_bible_lockscreen/features/settings/wallpaper_settings_screen.dart';

class VerseEditorControls extends StatefulWidget {
  final double fontSize;
  final TextAlign textAlign;
  final Color textColor;
  final String fontFamily;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<TextAlign> onAlignmentChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<String> onFontFamilyChanged;
  final bool useForDaily;
  final ValueChanged<bool> onUseForDailyChanged;
  final VoidCallback onRefreshPressed;
  final VoidCallback onCapturePressed;
  final Future<void> Function() onSetLockPressed;
  final String verse;
  final String reference;
  final String? backgroundUrl;
  final String? backgroundPath;
  final VerseTextPosition versePosition;
  final ValueChanged<VerseTextPosition> onVersePositionChanged;
  final ValueChanged<VerseTextPosition> onVersePositionCommitted;
  final WallpaperSchedule wallpaperSchedule;
  final Future<void> Function(WallpaperSchedule schedule) onScheduleChanged;

  const VerseEditorControls({
    super.key,
    required this.fontSize,
    required this.textAlign,
    required this.textColor,
    required this.fontFamily,
    required this.onFontSizeChanged,
    required this.onAlignmentChanged,
    required this.onColorChanged,
    required this.onFontFamilyChanged,
    required this.useForDaily,
    required this.onUseForDailyChanged,
    required this.onRefreshPressed,
    required this.onCapturePressed,
    required this.onSetLockPressed,
    required this.verse,
    required this.reference,
    required this.versePosition,
    required this.onVersePositionChanged,
    required this.onVersePositionCommitted,
    this.backgroundUrl,
    this.backgroundPath,
    required this.wallpaperSchedule,
    required this.onScheduleChanged,
  });

  @override
  State<VerseEditorControls> createState() => _VerseEditorControlsState();
}

class _VerseEditorControlsState extends State<VerseEditorControls> {
  bool expanded = false;

  // 🔹 ADDED: available fonts list
  final List<String> availableFonts = [
    'Roboto',
    'PlayfairDisplay',
    'GreatVibes',
    'Lora',
    'CormorantGaramond',
    'Cinzel',
  ];

  // Local copies to reflect changes immediately
  late double fontSize;
  late TextAlign textAlign;
  late Color textColor;
  late String fontFamily;
  late bool useForDaily;

  @override
  void initState() {
    super.initState();
    fontSize = widget.fontSize;
    textAlign = widget.textAlign;
    textColor = widget.textColor;
    fontFamily = widget.fontFamily;
    useForDaily = widget.useForDaily;
  }

  @override
  void didUpdateWidget(covariant VerseEditorControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    fontSize = widget.fontSize;
    textAlign = widget.textAlign;
    textColor = widget.textColor;
    fontFamily = widget.fontFamily;
    useForDaily = widget.useForDaily;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    if (!expanded) {
      return Align(
        alignment: Alignment.bottomLeft,
        child: SafeArea(
          top: false,
          left: true,
          right: false,
          bottom: true,
          minimum: const EdgeInsets.only(left: 12, bottom: 12),
          child: Material(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              onTap: () => setState(() => expanded = true),
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.settings, color: Colors.white, size: 22),
                    const SizedBox(width: 6),
                    const Text(
                      'Editor & Controls',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.expand_less, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: screenWidth,
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          color: Colors.black87,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Editor & Controls',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.expand_more, color: Colors.white),
                      onPressed: () => setState(() => expanded = false),
                    ),
                  ],
                ),
                ...[
                  // Font size slider
                  Row(
                    children: [
                      const Icon(Icons.format_size, color: Colors.white),
                      Expanded(
                        child: Slider(
                          value: fontSize,
                          min: 16,
                          max: 36,
                          divisions: 20,
                          label: fontSize.round().toString(),
                          onChanged: (v) {
                            setState(() => fontSize = v);
                            widget.onFontSizeChanged(v);
                          },
                        ),
                      ),
                    ],
                  ),

                  // 🔹 ADDED: Font family dropdown (below slider)
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.font_download, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: fontFamily,
                          dropdownColor: Colors.black87,
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white),
                          items: availableFonts
                              .map(
                                (f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(
                                    f,
                                    style: TextStyle(
                                      fontFamily: f,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (newFont) {
                            if (newFont == null) return;

                            setState(() => fontFamily = newFont);
                            widget.onFontFamilyChanged(newFont);
                          },
                        ),
                      ),
                    ],
                  ),

                  // Alignment buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _alignButton(Icons.format_align_left, TextAlign.left),
                      _alignButton(Icons.format_align_center, TextAlign.center),
                      _alignButton(Icons.format_align_right, TextAlign.right),
                    ],
                  ),

                  VersePositionSection(
                    verse: widget.verse,
                    reference: widget.reference,
                    fontSize: fontSize,
                    textAlign: textAlign,
                    textColor: textColor,
                    fontFamily: fontFamily,
                    position: widget.versePosition,
                    imageUrl: widget.backgroundUrl,
                    localPath: widget.backgroundPath,
                    onPositionChanged: widget.onVersePositionChanged,
                    onPositionCommitted: widget.onVersePositionCommitted,
                  ),

                  // Color picker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _colorDot(Colors.white),
                      _colorDot(Colors.yellowAccent),
                      _colorDot(Colors.orangeAccent),
                      _colorDot(Colors.lightBlueAccent),
                      _colorDot(Colors.purple.shade200),
                      _colorDot(Colors.greenAccent),
                      _colorDot(Colors.red.shade200),
                    ],
                  ),

                  // Use for daily toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Use these settings for Daily Verse',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: useForDaily,
                        onChanged: (v) {
                          setState(() => useForDaily = v);
                          widget.onUseForDailyChanged(v);
                        },
                        activeThumbColor: Colors.amber,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        tooltip: 'Refresh verse',
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: widget.onRefreshPressed,
                      ),
                      IconButton(
                        tooltip: 'Capture image',
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: widget.onCapturePressed,
                      ),
                      IconButton(
                        tooltip: 'Set as wallpaper',
                        icon: const Icon(Icons.wallpaper, color: Colors.white),
                        onPressed: () => widget.onSetLockPressed(),
                      ),
                      IconButton(
                        tooltip: 'Wallpaper settings',
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const WallpaperSettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  WallpaperScheduleSection(
                    schedule: widget.wallpaperSchedule,
                    onChanged: widget.onScheduleChanged,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _alignButton(IconData icon, TextAlign align) {
    return IconButton(
      icon: Icon(icon, color: textAlign == align ? Colors.amber : Colors.white),
      onPressed: () {
        setState(() => textAlign = align);
        widget.onAlignmentChanged(align);
      },
    );
  }

  Widget _colorDot(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() => textColor = color);
        widget.onColorChanged(color);
      },
      child: CircleAvatar(
        backgroundColor: color,
        radius: 14,
        child: textColor == color
            ? const Icon(Icons.check, color: Colors.black, size: 16)
            : null,
      ),
    );
  }
}
