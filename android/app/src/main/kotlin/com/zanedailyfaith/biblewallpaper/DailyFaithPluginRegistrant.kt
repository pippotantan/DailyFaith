package com.zanedailyfaith.biblewallpaper

import androidx.annotation.Keep
import io.flutter.embedding.engine.FlutterEngine

/**
 * Registers app-local plugins that are not listed in GeneratedPluginRegistrant.
 *
 * WorkManager's background [FlutterEngine] only auto-registers pubspec plugins.
 * This entry point is invoked from the WorkManager worker (and from [MainActivity])
 * so wallpaper MethodChannel handlers exist in both the UI and background isolates.
 *
 * [Keep] plus ProGuard keep rules prevent R8 from renaming this class; the
 * worker looks it up by name via Class.forName.
 */
@Keep
object DailyFaithPluginRegistrant {
    @JvmStatic
    fun registerWith(engine: FlutterEngine) {
        if (engine.plugins.has(WallpaperPlugin::class.java)) return
        engine.plugins.add(WallpaperPlugin())
    }
}
