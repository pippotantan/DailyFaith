# Keep app-local plugins that WorkManager looks up by class name
# (Class.forName) when starting the background FlutterEngine.
-keep class com.zanedailyfaith.biblewallpaper.DailyFaithPluginRegistrant {
    public static void registerWith(io.flutter.embedding.engine.FlutterEngine);
}
-keep class com.zanedailyfaith.biblewallpaper.WallpaperPlugin { *; }
