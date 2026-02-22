package com.example.china_chess_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.example.china_chess_app/engine"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getNativeLibraryDir" -> {
                        val nativeLibDir = applicationContext.applicationInfo.nativeLibraryDir
                        result.success(nativeLibDir)
                    }
                    "getCodeCacheDir" -> {
                        // code_cache is often more permissive for execution on Android 10+
                        val codeCacheDir = applicationContext.codeCacheDir.absolutePath
                        result.success(codeCacheDir)
                    }
                    "getFilesDir" -> {
                        val filesDir = applicationContext.filesDir.absolutePath
                        result.success(filesDir)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
