package com.example.aniket_pro_ai

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "aniket_pro_ai/gallery"
    private val REQ_DELETE = 9001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "deleteFiles" -> {
                        val paths = call.argument<List<String>>("paths") ?: emptyList()
                        handleDelete(paths, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleDelete(paths: List<String>, result: MethodChannel.Result) {
        val uris = paths.mapNotNull { uriForPath(it) }
        if (uris.isEmpty()) {
            result.success(0)
            return
        }
        pendingResult = result
        try {
            val pi = MediaStore.createDeleteRequest(this, uris)
            startIntentSenderForResult(pi.intentSender, REQ_DELETE, null, 0, 0, 0)
        } catch (e: Exception) {
            pendingResult = null
            result.error("DELETE_FAILED", e.message, null)
        }
    }

    private fun uriForPath(path: String): Uri? {
        val projection = arrayOf(MediaStore.Images.Media._ID)
        val selection = "${MediaStore.Images.Media.DATA}=?"
        val args = arrayOf(path)
        contentResolver.query(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            projection, selection, args, null
        )?.use { c ->
            if (c.moveToFirst()) {
                val id = c.getLong(0)
                return Uri.withAppendedId(
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id
                )
            }
        }
        return null
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQ_DELETE) {
            val r = pendingResult
            pendingResult = null
            if (r != null) {
                r.success(if (resultCode == Activity.RESULT_OK) 1 else 0)
            }
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}
