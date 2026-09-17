package com.zanedailyfaith.biblewallpaper

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        DailyFaithPluginRegistrant.registerWith(flutterEngine)
    }
}
