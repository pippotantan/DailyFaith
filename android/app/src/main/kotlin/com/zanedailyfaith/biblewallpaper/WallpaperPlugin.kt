package com.zanedailyfaith.biblewallpaper

import android.app.WallpaperManager
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Rect
import android.view.WindowManager
import androidx.annotation.Keep
import androidx.annotation.RequiresApi
import android.media.MediaScannerConnection
import kotlin.math.roundToInt
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

/**
 * Registers the wallpaper MethodChannel on any [io.flutter.embedding.engine.FlutterEngine],
 * including the WorkManager background engine. [MainActivity] cannot do this because
 * WorkManager creates a separate engine that never runs [MainActivity.configureFlutterEngine].
 */
@Keep
class WallpaperPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private var appContext: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL).also {
            it.setMethodCallHandler(this)
        }
        Log.i(TAG, "Wallpaper MethodChannel attached")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        appContext = null
        Log.i(TAG, "Wallpaper MethodChannel detached")
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val context = appContext
        if (context == null) {
            result.error("NO_CONTEXT", "Wallpaper plugin is not attached", null)
            return
        }

        when (call.method) {
            "setWallpaper" -> {
                val path = call.argument<String>("path")
                val location = call.argument<String>("location") ?: "lockScreen"
                val fitHomeToDisplay = call.argument<Boolean>("fitHomeToDisplay") ?: false
                if (path == null) {
                    result.error("INVALID_ARGS", "Path argument is required", null)
                    return
                }
                try {
                    setWallpaperFromPath(context, path, location, fitHomeToDisplay)
                    Log.i(
                        TAG,
                        "setWallpaper succeeded location=$location fitHomeToDisplay=$fitHomeToDisplay",
                    )
                    result.success(true)
                } catch (e: Exception) {
                    Log.e(TAG, "setWallpaper failed location=$location", e)
                    result.error("WALLPAPER_ERROR", e.message, e.stackTraceToString())
                }
            }

            "setWallpaperUri" -> {
                val uri = call.argument<String>("uri")
                if (uri == null) {
                    result.error("INVALID_ARGS", "URI argument is required", null)
                    return
                }
                try {
                    setWallpaperFromUri(context, uri)
                    Log.i(TAG, "setWallpaperUri succeeded")
                    result.success(true)
                } catch (e: Exception) {
                    Log.e(TAG, "setWallpaperUri failed", e)
                    result.error("WALLPAPER_ERROR", e.message, null)
                }
            }

            "hasWallpaperPermission" -> {
                val permission = android.Manifest.permission.SET_WALLPAPER
                val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
                } else {
                    true
                }
                result.success(granted)
            }

            "saveImageToGallery" -> {
                val image = call.argument<ByteArray>("imageBytes")
                val quality = call.argument<Int>("quality") ?: 100
                val name = call.argument<String>("name")
                result.success(saveImageToGallery(context, image, quality, name))
            }

            else -> result.notImplemented()
        }
    }

    companion object {
        const val CHANNEL = "com.zanedailyfaith.biblewallpaper/wallpaper"
        private const val TAG = "DailyFaithWallpaper"

        fun setWallpaperFromPath(
            context: Context,
            path: String,
            location: String,
            fitHomeToDisplay: Boolean = false,
        ) {
            val file = File(path)
            if (!file.exists()) {
                throw IllegalArgumentException("Wallpaper file not found: $path")
            }
            val wallpaperManager = WallpaperManager.getInstance(context)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                when (location) {
                    "lockScreen" -> applyStream(wallpaperManager, file, WallpaperManager.FLAG_LOCK)
                    "homeScreen" -> applySystemWallpaper(
                        context,
                        wallpaperManager,
                        file,
                        fitHomeToDisplay,
                    )
                    "both" -> {
                        applySystemWallpaper(
                            context,
                            wallpaperManager,
                            file,
                            fitHomeToDisplay,
                        )
                        applyStream(wallpaperManager, file, WallpaperManager.FLAG_LOCK)
                    }
                    else -> applyStream(wallpaperManager, file, WallpaperManager.FLAG_LOCK)
                }
            } else {
                file.inputStream().use { stream ->
                    @Suppress("DEPRECATION")
                    wallpaperManager.setStream(stream)
                }
            }
        }

        @RequiresApi(Build.VERSION_CODES.N)
        private fun applySystemWallpaper(
            context: Context,
            wallpaperManager: WallpaperManager,
            file: File,
            fitHomeToDisplay: Boolean,
        ) {
            if (fitHomeToDisplay) {
                applySystemFittedToDisplay(context, wallpaperManager, file)
            } else {
                applyStream(wallpaperManager, file, WallpaperManager.FLAG_SYSTEM)
            }
        }

        /**
         * Home wallpaper ([WallpaperManager.FLAG_SYSTEM]) is a scrollable surface.
         * [WallpaperManager.setStream] with a null crop hint lets the OEM pick the
         * initial viewport. From a foreground Activity the launcher usually centers
         * it; from a WorkManager [android.content.Context] there is no window token,
         * so Samsung One UI often leaves the offset at 0 (left). The verse, which is
         * centered in a 1080-wide image, is then cropped on the right.
         *
         * Fitting the bitmap to the real display size makes FLAG_SYSTEM a 1:1 screen
         * wallpaper so the offset no longer matters. Lock screen is unchanged.
         */
        @RequiresApi(Build.VERSION_CODES.N)
        private fun applySystemFittedToDisplay(
            context: Context,
            wallpaperManager: WallpaperManager,
            file: File,
        ) {
            val (destW, destH) = displaySize(context)
            if (destW <= 0 || destH <= 0) {
                Log.w(TAG, "Display size unavailable (${destW}x${destH}); using default home crop")
                applyStream(wallpaperManager, file, WallpaperManager.FLAG_SYSTEM)
                return
            }

            val original = BitmapFactory.decodeFile(file.absolutePath)
                ?: throw IllegalStateException("Failed to decode wallpaper: ${file.absolutePath}")
            val fitted = centerCropToSize(original, destW, destH)
            try {
                Log.i(
                    TAG,
                    "FLAG_SYSTEM fitted ${original.width}x${original.height} -> ${fitted.width}x${fitted.height} (display ${destW}x${destH})",
                )
                wallpaperManager.setBitmap(
                    fitted,
                    Rect(0, 0, fitted.width, fitted.height),
                    true,
                    WallpaperManager.FLAG_SYSTEM,
                )
            } finally {
                if (fitted !== original) {
                    fitted.recycle()
                }
                original.recycle()
            }
        }

        private fun displaySize(context: Context): Pair<Int, Int> {
            val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val bounds = windowManager.maximumWindowMetrics.bounds
                bounds.width() to bounds.height()
            } else {
                val metrics = android.util.DisplayMetrics()
                @Suppress("DEPRECATION")
                windowManager.defaultDisplay.getRealMetrics(metrics)
                metrics.widthPixels to metrics.heightPixels
            }
        }

        private fun centerCropToSize(source: Bitmap, destW: Int, destH: Int): Bitmap {
            if (source.width == destW && source.height == destH) {
                return source
            }
            val scale = maxOf(
                destW.toFloat() / source.width,
                destH.toFloat() / source.height,
            )
            val scaledW = (source.width * scale).roundToInt().coerceAtLeast(1)
            val scaledH = (source.height * scale).roundToInt().coerceAtLeast(1)
            val scaled = Bitmap.createScaledBitmap(source, scaledW, scaledH, true)
            val x = ((scaled.width - destW) / 2).coerceAtLeast(0)
            val y = ((scaled.height - destH) / 2).coerceAtLeast(0)
            val w = destW.coerceAtMost(scaled.width - x)
            val h = destH.coerceAtMost(scaled.height - y)
            if (x == 0 && y == 0 && w == scaled.width && h == scaled.height) {
                return scaled
            }
            val cropped = Bitmap.createBitmap(scaled, x, y, w, h)
            if (scaled !== source) {
                scaled.recycle()
            }
            return cropped
        }

        private fun applyStream(wallpaperManager: WallpaperManager, file: File, which: Int) {
            file.inputStream().use { stream ->
                wallpaperManager.setStream(stream, null, true, which)
            }
        }

        fun setWallpaperFromUri(context: Context, uriString: String) {
            val wallpaperManager = WallpaperManager.getInstance(context)
            val contentUri = Uri.parse(uriString)
            val inputStream = context.contentResolver.openInputStream(contentUri)
                ?: throw IllegalStateException("Failed to open input stream for URI")
            inputStream.use { stream ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    wallpaperManager.setStream(stream, null, true, WallpaperManager.FLAG_LOCK)
                } else {
                    @Suppress("DEPRECATION")
                    wallpaperManager.setStream(stream)
                }
            }
        }
    }

    private fun saveImageToGallery(
        context: Context,
        imageBytes: ByteArray?,
        quality: Int,
        name: String?,
    ): HashMap<String, Any?> {
        if (imageBytes == null) {
            return hashMapOf("isSuccess" to false, "error" to "parameters error")
        }
        val bmp = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
            ?: return hashMapOf("isSuccess" to false, "error" to "invalid image bytes")

        val fileName = name ?: System.currentTimeMillis().toString()
        var fileUri: Uri? = null
        var success = false
        try {
            fileUri = generateImageUri(context, fileName)
            if (fileUri != null) {
                context.contentResolver.openOutputStream(fileUri)?.use { fos ->
                    success = bmp.compress(
                        Bitmap.CompressFormat.JPEG,
                        quality.coerceIn(0, 100),
                        fos,
                    )
                    fos.flush()
                }
            }
        } catch (e: IOException) {
            deleteFailedMedia(context, fileUri)
            bmp.recycle()
            return hashMapOf("isSuccess" to false, "error" to e.toString())
        }
        bmp.recycle()

        return if (success) {
            finishPendingMedia(context, fileUri)
            sendBroadcast(context, fileUri)
            hashMapOf("isSuccess" to true, "filePath" to fileUri.toString())
        } else {
            deleteFailedMedia(context, fileUri)
            hashMapOf("isSuccess" to false, "error" to "saveImageToGallery fail")
        }
    }

    private fun generateImageUri(context: Context, fileName: String): Uri? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_PICTURES)
                put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            context.contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
        } else {
            @Suppress("DEPRECATION")
            val storePath = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_PICTURES,
            ).absolutePath
            val appDir = File(storePath).apply { if (!exists()) mkdirs() }
            Uri.fromFile(File(appDir, "$fileName.jpg"))
        }
    }

    private fun sendBroadcast(context: Context, fileUri: Uri?) {
        fileUri?.takeIf { it.scheme == "file" }?.path?.let { path ->
            MediaScannerConnection.scanFile(context, arrayOf(path), null, null)
        }
    }

    private fun finishPendingMedia(context: Context, fileUri: Uri?) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q || fileUri == null) return
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.IS_PENDING, 0)
        }
        context.contentResolver.update(fileUri, values, null, null)
    }

    private fun deleteFailedMedia(context: Context, fileUri: Uri?) {
        when (fileUri?.scheme) {
            "file" -> fileUri.path?.let { File(it).delete() }
            null -> return
            else -> context.contentResolver.delete(fileUri, null, null)
        }
    }
}
