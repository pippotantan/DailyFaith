import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:zane_bible_lockscreen/core/services/gallery_service.dart';
import 'package:zane_bible_lockscreen/core/models/bible_verse.dart';
import 'package:zane_bible_lockscreen/core/services/background_provider.dart';
import 'package:zane_bible_lockscreen/core/services/image_generation_service.dart';
import 'package:zane_bible_lockscreen/core/services/settings_service.dart';
import 'package:zane_bible_lockscreen/core/services/verse_repository.dart';
import 'package:zane_bible_lockscreen/core/models/verse_text_position.dart';
import 'package:zane_bible_lockscreen/core/models/wallpaper_schedule.dart';
import 'package:zane_bible_lockscreen/core/services/wallpaper_service.dart';
import 'package:zane_bible_lockscreen/core/services/workmanager_service.dart';
import 'package:zane_bible_lockscreen/features/editor/verse_editor_controls.dart';
import 'package:zane_bible_lockscreen/features/editor/verse_editor_state.dart';
import 'package:zane_bible_lockscreen/widgets/verse_background_preview.dart';

class VerseScreen extends StatefulWidget {
  const VerseScreen({super.key});

  @override
  State<VerseScreen> createState() => _VerseScreenState();
}

class _VerseScreenState extends State<VerseScreen> {
  BibleVerse? verse;
  String? backgroundUrl;
  String? backgroundPath;
  String? photoAttribution;
  bool loading = true;
  final editor = VerseEditorState();
  bool useForDaily = false;
  WallpaperSchedule wallpaperSchedule = WallpaperSchedule.initial;

  @override
  void initState() {
    super.initState();
    loadVerse();
    _loadEditorSettings();
  }

  Future<void> _loadEditorSettings() async {
    try {
      final saved = await SettingsService.loadEditorState();
      final use = await SettingsService.getUseEditorForDaily();
      final schedule = await SettingsService.loadWallpaperSchedule();

      setState(() {
        editor.fontSize = saved.fontSize;
        editor.textAlign = saved.textAlign;
        editor.textColor = saved.textColor;
        editor.fontFamily = saved.fontFamily; // ← actual font from pubspec.yaml
        editor.position = saved.position;
        useForDaily = use;
        wallpaperSchedule = schedule;
      });
    } catch (e) {
      developer.log(
        'Failed to load editor settings, using defaults: $e',
        name: 'VerseScreen',
      );
      setState(() {
        editor.fontSize = 42;
        editor.textAlign = TextAlign.center;
        editor.textColor = Colors.white;
        editor.fontFamily = 'Roboto'; // fallback
        editor.position = VerseTextPosition.legacy;
        useForDaily = false;
        wallpaperSchedule = WallpaperSchedule.initial;
      });
    }
  }

  Future<void> _onVersePositionCommitted(VerseTextPosition next) async {
    setState(() => editor.position = next);
    if (next.isCustom) {
      await SettingsService.saveVersePosition(next);
      return;
    }
    await SettingsService.clearVersePosition();
  }

  Future<void> _onScheduleChanged(WallpaperSchedule next) async {
    final error = next.validationError;
    if (error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final previous = wallpaperSchedule;
    final timeChanged =
        previous.hour != next.hour || previous.minute != next.minute;
    final turningOff = previous.enabled && !next.enabled;
    try {
      await SettingsService.saveWallpaperSchedule(next);
      String? message;
      if (next.enabled) {
        message = await WorkManagerService.enqueueConfigured(
          allowSameMinuteGrace: timeChanged,
        );
      } else {
        await WorkManagerService.cancelDailyVerse();
      }
      if (!mounted) return;
      setState(() => wallpaperSchedule = next);
      if (turningOff) {
        message = 'Schedule is off. No wallpaper update is queued.';
      }
      if (message != null && (next.enabled || turningOff)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e, stackTrace) {
      developer.log(
        'Schedule update failed: $e',
        name: 'VerseScreen',
        stackTrace: stackTrace,
      );
      try {
        await SettingsService.saveWallpaperSchedule(previous);
      } catch (rollbackError) {
        developer.log(
          'Schedule rollback failed: $rollbackError',
          name: 'VerseScreen',
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update the schedule.')),
      );
    }
  }

  Future<void> loadVerse() async {
    setState(() => loading = true);

    final verseRepo = VerseRepository();
    final topic = await SettingsService.getVerseTopic();
    final keyword = await SettingsService.getBackgroundKeyword();

    try {
      final verseResult = await verseRepo.fetchRandomVerse(topicId: topic);
      final bgResult = await BackgroundProvider.fetchBackground(
        keywordId: keyword,
      );

      if (!mounted) return;
      setState(() {
        verse = verseResult;
        backgroundUrl = bgResult?.imageUrl;
        backgroundPath = bgResult?.localPath;
        photoAttribution = bgResult?.attributionText;
        loading = false;
      });
      if (bgResult == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No background available. Add images in Settings or check your connection.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
      }
    }
  }

  Future<void> generateImage() async {
    if (verse == null) return;
    if (backgroundUrl == null && backgroundPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a background in Settings to generate an image.'),
        ),
      );
      return;
    }

    try {
      final image = await ImageGenerationService.generateVerseImage(
        backgroundUrl: backgroundUrl,
        backgroundPath: backgroundPath,
        verse: verse!.text,
        reference: verse!.reference,
        fontSize: editor.fontSize,
        textAlign: editor.textAlign,
        textColor: editor.textColor,
        fontFamily: editor.fontFamily,
        photoAttribution: photoAttribution,
        position: editor.position,
      );

      final name = 'verse_${DateTime.now().millisecondsSinceEpoch}';
      final result = await GalleryService.saveImage(image, name: name);

      if (!mounted) return;

      final isSuccess = result['isSuccess'] == true;
      if (isSuccess) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Image saved to gallery')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save to gallery: ${result['error'] ?? 'Permission denied or storage unavailable'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate image: $e')));
    }
  }

  Future<void> generateAndSetWallpaper() async {
    if (verse == null) return;
    if (backgroundUrl == null && backgroundPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a background in Settings to set wallpaper.'),
        ),
      );
      return;
    }

    try {
      final image = await ImageGenerationService.generateVerseImage(
        backgroundUrl: backgroundUrl,
        backgroundPath: backgroundPath,
        verse: verse!.text,
        reference: verse!.reference,
        fontSize: editor.fontSize,
        textAlign: editor.textAlign,
        textColor: editor.textColor,
        fontFamily: editor.fontFamily,
        photoAttribution: photoAttribution,
        position: editor.position,
      );

      final file = await ImageGenerationService.saveImage(
        image,
        'manual_verse.png',
      );

      final target = await SettingsService.getWallpaperTarget();

      var location = WallpaperService.lockScreen;
      if (target == WallpaperTarget.homeScreenOnly) {
        location = WallpaperService.homeScreen;
      } else if (target == WallpaperTarget.both) {
        location = WallpaperService.both;
      }

      await WallpaperService.setWallpaper(file, location: location);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallpaper set successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to set wallpaper: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading || verse == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                VerseBackgroundPreview(
                  imageUrl: backgroundUrl,
                  localPath: backgroundPath,
                  verse: verse!.text,
                  reference: verse!.reference,
                  fontSize: editor.fontSize,
                  textAlign: editor.textAlign,
                  textColor: editor.textColor,
                  fontFamily: editor.fontFamily,
                  position: editor.position,
                ),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 5,
                  child: VerseEditorControls(
                    fontSize: editor.fontSize,
                    textAlign: editor.textAlign,
                    textColor: editor.textColor,
                    useForDaily: useForDaily,
                    onFontSizeChanged: (v) => setState(() {
                      final updated = editor.copyWith(fontSize: v);
                      setState(() {
                        editor
                          ..fontSize = updated.fontSize
                          ..textAlign = updated.textAlign
                          ..textColor = updated.textColor
                          ..fontFamily = updated.fontFamily;
                      });
                      SettingsService.saveEditorState(updated);
                    }),
                    onAlignmentChanged: (a) => setState(() {
                      final updated = editor.copyWith(textAlign: a);
                      setState(() {
                        editor
                          ..fontSize = updated.fontSize
                          ..textAlign = updated.textAlign
                          ..textColor = updated.textColor
                          ..fontFamily = updated.fontFamily;
                      });
                      SettingsService.saveEditorState(updated);
                    }),
                    onColorChanged: (c) => setState(() {
                      final updated = editor.copyWith(textColor: c);
                      setState(() {
                        editor
                          ..fontSize = updated.fontSize
                          ..textAlign = updated.textAlign
                          ..textColor = updated.textColor
                          ..fontFamily = updated.fontFamily;
                      });
                      SettingsService.saveEditorState(updated);
                    }),
                    fontFamily: editor.fontFamily,
                    onFontFamilyChanged: (f) => setState(() {
                      final updated = editor.copyWith(fontFamily: f);
                      setState(() {
                        editor
                          ..fontSize = updated.fontSize
                          ..textAlign = updated.textAlign
                          ..textColor = updated.textColor
                          ..fontFamily = updated.fontFamily;
                      });
                      SettingsService.saveEditorState(updated);
                    }),
                    onUseForDailyChanged: (v) async {
                      setState(() => useForDaily = v);
                      await SettingsService.setUseEditorForDaily(v);
                    },
                    onRefreshPressed: loadVerse,
                    onCapturePressed: generateImage,
                    onSetLockPressed: () async =>
                        await generateAndSetWallpaper(),
                    verse: verse!.text,
                    reference: verse!.reference,
                    backgroundUrl: backgroundUrl,
                    backgroundPath: backgroundPath,
                    versePosition: editor.position,
                    onVersePositionChanged: (next) {
                      setState(() => editor.position = next);
                    },
                    onVersePositionCommitted: _onVersePositionCommitted,
                    wallpaperSchedule: wallpaperSchedule,
                    onScheduleChanged: _onScheduleChanged,
                  ),
                ),
              ],
            ),
      floatingActionButton: null,
    );
  }
}
