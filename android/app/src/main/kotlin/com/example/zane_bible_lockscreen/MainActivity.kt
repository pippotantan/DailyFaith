package com.example.zane_bible_lockscreen

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.WallpaperManager
import android.content.ContentValues
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaScannerConnection
import android.net.Uri
import java.io.File
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.zane_bible_lockscreen/wallpaper"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setWallpaper" -> {
                    val path = call.argument<String>("path")
                    val location = call.argument<String>("location") ?: "lockScreen"
                    
                    if (path != null) {
                        try {
                            val file = File(path)
                            if (!file.exists()) {
                                result.error("FILE_NOT_FOUND", "Wallpaper file not found: $path", null)
                                return@setMethodCallHandler
                            }
                            
                            val wallpaperManager = WallpaperManager.getInstance(this)
                            val fileInputStream = file.inputStream()
                            
                            try {
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                    when (location) {
                                        "lockScreen" -> wallpaperManager.setStream(fileInputStream, null, true, WallpaperManager.FLAG_LOCK)
                                        "homeScreen" -> wallpaperManager.setStream(fileInputStream, null, true, WallpaperManager.FLAG_SYSTEM)
                                        "both" -> wallpaperManager.setStream(fileInputStream)
                                        else -> wallpaperManager.setStream(fileInputStream, null, true, WallpaperManager.FLAG_LOCK)
                                    }
                                } else {
                                    @Suppress("DEPRECATION")
                                    wallpaperManager.setStream(fileInputStream)
                                }
                                
                                fileInputStream.close()
                                result.success(true)
                            } catch (e: Exception) {
                                fileInputStream.close()
                                result.error("WALLPAPER_ERROR", "Failed to set wallpaper: ${e.message}", e.stackTrace.toString())
                            }
                        } catch (e: Exception) {
                            result.error("ERROR", "Error setting wallpaper: ${e.message}", e.stackTrace.toString())
                        }
                    } else {
                        result.error("INVALID_ARGS", "Path argument is required", null)
                    }
                }
                
                "setWallpaperUri" -> {
                    val uri = call.argument<String>("uri")
                    
                    if (uri != null) {
                        try {
                            val wallpaperManager = WallpaperManager.getInstance(this)
                            val contentUri = Uri.parse(uri)
                            val inputStream = contentResolver.openInputStream(contentUri)
                            
                            if (inputStream != null) {
                                try {
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                        wallpaperManager.setStream(inputStream, null, true, WallpaperManager.FLAG_LOCK)
                                    } else {
                                        @Suppress("DEPRECATION")
                                        wallpaperManager.setStream(inputStream)
                                    }
                                    
                                    inputStream.close()
                                    result.success(true)
                                } catch (e: Exception) {
                                    inputStream.close()
                                    result.error("WALLPAPER_ERROR", "Failed to set wallpaper: ${e.message}", null)
                                }
                            } else {
                                result.error("STREAM_ERROR", "Failed to open input stream for URI", null)
                            }
                        } catch (e: Exception) {
                            result.error("ERROR", "Error setting wallpaper from URI: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "URI argument is required", null)
                    }
                }
                
                "hasWallpaperPermission" -> {
                    val permission = android.Manifest.permission.SET_WALLPAPER
                    val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
                    } else {
                        true
                    }
                    result.success(hasPermission)
                }

                "saveImageToGallery" -> {
                    val image = call.argument<ByteArray>("imageBytes")
                    val quality = call.argument<Int>("quality") ?: 100
                    val name = call.argument<String>("name")
                    result.success(saveImageToGallery(image, quality, name))
                }
                
                else -> result.notImplemented()
            }
        }
    }

    private fun saveImageToGallery(
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
            fileUri = generateImageUri(fileName)
            if (fileUri != null) {
                contentResolver.openOutputStream(fileUri)?.use { fos ->
                    success = bmp.compress(
                        Bitmap.CompressFormat.JPEG,
                        quality.coerceIn(0, 100),
                        fos,
                    )
                    fos.flush()
                }
            }
        } catch (e: IOException) {
            deleteFailedMedia(fileUri)
            bmp.recycle()
            return hashMapOf("isSuccess" to false, "error" to e.toString())
        }
        bmp.recycle()

        return if (success) {
            finishPendingMedia(fileUri)
            sendBroadcast(fileUri)
            hashMapOf("isSuccess" to true, "filePath" to fileUri.toString())
        } else {
            deleteFailedMedia(fileUri)
            hashMapOf("isSuccess" to false, "error" to "saveImageToGallery fail")
        }
    }

    private fun generateImageUri(fileName: String): Uri? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_PICTURES)
                put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
        } else {
            @Suppress("DEPRECATION")
            val storePath = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_PICTURES,
            ).absolutePath
            val appDir = File(storePath).apply { if (!exists()) mkdirs() }
            Uri.fromFile(File(appDir, "$fileName.jpg"))
        }
    }

    private fun sendBroadcast(fileUri: Uri?) {
        fileUri?.takeIf { it.scheme == "file" }?.path?.let { path ->
            MediaScannerConnection.scanFile(this, arrayOf(path), null, null)
        }
    }

    private fun finishPendingMedia(fileUri: Uri?) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q || fileUri == null) return
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.IS_PENDING, 0)
        }
        contentResolver.update(fileUri, values, null, null)
    }

    private fun deleteFailedMedia(fileUri: Uri?) {
        when (fileUri?.scheme) {
            "file" -> fileUri.path?.let { File(it).delete() }
            null -> return
            else -> contentResolver.delete(fileUri, null, null)
        }
    }
}
