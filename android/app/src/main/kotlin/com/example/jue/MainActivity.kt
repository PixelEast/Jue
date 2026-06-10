package com.example.jue

import android.app.usage.StorageStatsManager
import android.content.Context
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.os.storage.StorageManager
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.jue/storage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getAppSize") {
                try {
                    val storageStatsManager = getSystemService(Context.STORAGE_STATS_SERVICE) as StorageStatsManager
                    val storageManager = getSystemService(Context.STORAGE_SERVICE) as StorageManager
                    val uuid = storageManager.primaryStorageVolume.uuid
                    val storageUuid = if (uuid != null) java.util.UUID.fromString(uuid) else StorageManager.UUID_DEFAULT
                    val packageName = packageName
                    val appSize = storageStatsManager.queryStatsForUid(storageUuid, android.os.Process.myUid())
                    val totalSize = appSize.appBytes + appSize.dataBytes + appSize.cacheBytes
                    result.success(totalSize)
                } catch (e: Exception) {
                    result.success(0L)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.setBackgroundDrawableResource(android.R.color.white)
        window.decorView.setBackgroundColor(Color.WHITE)
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
            window.isStatusBarContrastEnforced = false
        }
        
        window.decorView.systemUiVisibility = (window.decorView.systemUiVisibility
            or android.view.View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR
            or android.view.View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR)
    }
}
