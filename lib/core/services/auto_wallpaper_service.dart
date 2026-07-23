import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:wallpaper_manager_flutter/wallpaper_manager_flutter.dart';
import 'package:zane_bible_lockscreen/core/models/bible_verse.dart';
import 'package:zane_bible_lockscreen/core/services/background_provider.dart';
import 'package:zane_bible_lockscreen/core/services/image_generation_service.dart';
import 'package:zane_bible_lockscreen/core/services/settings_service.dart';
import 'package:zane_bible_lockscreen/core/services/verse_repository.dart';

class AutoWallpaperService {
  static Future<void> run() async {
    developer.log('Starting wallpaper generation', name: 'AutoWallpaperService');

    try {
      // ✅ 1. Fetch random verse (uses API when online, offline store when not)
      final topic = await SettingsService.getVerseTopic();
      final BibleVerse verse =
          await VerseRepository().fetchRandomVerse(topicId: topic);

      // ✅ 2. Fetch background (Pexels when online, or local gallery for offline)
      final keyword = await SettingsService.getBackgroundKeyword();
      final bgResult = await BackgroundProvider.fetchBackground(keywordId: keyword);

      if (bgResult == null) {
        developer.log('No background available. Skipping.', name: 'AutoWallpaperService');
        return;
      }

      // ✅ 4. Load editor settings (always)
      double fontSize = 42;
      TextAlign textAlign = TextAlign.center;
      Color textColor = Colors.white;
      String fontFamily = 'Roboto';

      try {
        final editor = await SettingsService.loadEditorState();
        fontSize = editor.fontSize;
        textAlign = editor.textAlign;
        textColor = editor.textColor;
        fontFamily = editor.fontFamily;
        developer.log('Editor settings applied', name: 'AutoWallpaperService');
      } catch (e) {
        developer.log(
          'Failed to load editor settings, using defaults',
          name: 'AutoWallpaperService',
        );
      }

      // ✅ 5. Load saved editor settings if enabled
      try {
        final useEditor = await SettingsService.getUseEditorForDaily();
        if (useEditor) {
          final editor = await SettingsService.loadEditorState();
          fontSize = editor.fontSize;
          textAlign = editor.textAlign;
          textColor = editor.textColor;
          fontFamily = editor.fontFamily;
          developer.log('Editor settings loaded', name: 'AutoWallpaperService');
        }
      } catch (e) {
        developer.log('Editor settings failed, using defaults', name: 'AutoWallpaperService');
      }

      // 6️⃣ Generate image using centralized service (with photo attribution when applicable)
      final image = await ImageGenerationService.generateVerseImage(
        backgroundUrl: bgResult.imageUrl,
        backgroundPath: bgResult.localPath,
        verse: verse.text,
        reference: verse.reference,
        fontSize: fontSize,
        textAlign: textAlign,
        textColor: textColor,
        fontFamily: fontFamily,
        photoAttribution: bgResult.attributionText,
      );

      developer.log('Image generated (${image.length} bytes)', name: 'AutoWallpaperService');

      // ✅ 7. Save file
      final file = await ImageGenerationService.saveImage(
        image,
        'daily_verse.png',
      );

      developer.log('Image saved at ${file.path}', name: 'AutoWallpaperService');

      // ✅ 8. Determine wallpaper target
      String locationStr = 'both';
      try {
        final target = await SettingsService.getWallpaperTarget();
        locationStr = target == WallpaperTarget.lockScreenOnly
            ? 'lockScreen'
            : target == WallpaperTarget.homeScreenOnly
            ? 'homeScreen'
            : 'both';
      } catch (_) {}

      // ✅ 9. Set wallpaper
      bool wallpaperSet = false;

      try {
        int location = WallpaperManagerFlutter.lockScreen;

        if (locationStr == 'homeScreen') {
          location = WallpaperManagerFlutter.homeScreen;
        } else if (locationStr == 'both') {
          location = WallpaperManagerFlutter.bothScreens;
        }

        await WallpaperManagerFlutter().setWallpaper(file, location);

        wallpaperSet = true;
        developer.log('Wallpaper set successfully', name: 'AutoWallpaperService');
      } catch (e) {
        developer.log('Wallpaper plugin failed: $e', name: 'AutoWallpaperService');
      }

      if (wallpaperSet) {
        developer.log('Wallpaper set successfully', name: 'AutoWallpaperService');
      } else {
        developer.log('Wallpaper may not have been set', name: 'AutoWallpaperService');
      }
    } catch (e, stackTrace) {
      developer.log('ERROR: $e', name: 'AutoWallpaperService', stackTrace: stackTrace);
      rethrow;
    }
  }
}
