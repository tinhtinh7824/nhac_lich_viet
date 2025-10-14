package com.example.nhac_lich_viet

import android.content.ContentValues
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "nhac_lich_viet/image_saver"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveImage" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val name = call.argument<String>("name") ?: "nhac_lich_viet.png"
                    if (bytes == null) {
                        result.error("INVALID_ARGUMENT", "Image bytes are null", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val saved = saveImageToGallery(bytes, name)
                        result.success(saved)
                    } catch (e: Exception) {
                        result.error("SAVE_ERROR", e.localizedMessage, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveImageToGallery(bytes: ByteArray, fileName: String): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = contentResolver
            val contentValues = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, "image/png")
                put(
                    MediaStore.MediaColumns.RELATIVE_PATH,
                    Environment.DIRECTORY_PICTURES + File.separator + "NhacLichViet"
                )
            }
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
                ?: return false
            resolver.openOutputStream(uri).use { stream ->
                if (stream == null) return false
                stream.write(bytes)
                stream.flush()
            }
            true
        } else {
            val picturesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
            val appDir = File(picturesDir, "NhacLichViet")
            if (!appDir.exists()) {
                appDir.mkdirs()
            }
            val imageFile = File(appDir, fileName)
            var outputStream: OutputStream? = null
            return try {
                outputStream = FileOutputStream(imageFile)
                outputStream.write(bytes)
                outputStream.flush()
                MediaScannerConnection.scanFile(
                    this,
                    arrayOf(imageFile.absolutePath),
                    arrayOf("image/png"),
                    null
                )
                true
            } catch (e: Exception) {
                false
            } finally {
                outputStream?.close()
            }
        }
    }
}
