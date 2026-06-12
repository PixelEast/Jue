package com.example.jue

import android.app.usage.StorageStatsManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.os.storage.StorageManager
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val STORAGE_CHANNEL = "com.example.jue/storage"
    private val WIDGET_CHANNEL = "com.example.jue/widget"
    private var widgetChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getAppSize") {
                try {
                    val storageStatsManager = getSystemService(Context.STORAGE_STATS_SERVICE) as StorageStatsManager
                    val storageManager = getSystemService(Context.STORAGE_SERVICE) as StorageManager
                    val uuid = storageManager.primaryStorageVolume.uuid
                    val storageUuid = if (uuid != null) java.util.UUID.fromString(uuid) else StorageManager.UUID_DEFAULT
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

        widgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
        widgetChannel?.setMethodCallHandler { call, result ->
            if (call.method == "clearPendingExecution") {
                val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                prefs.edit().remove("flutter.widget_pending_execution").apply()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        // Check if launched from widget click
        handleWidgetIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleWidgetIntent(intent)
    }

    private fun handleWidgetIntent(intent: Intent?) {
        val decisionId = intent?.getStringExtra("widget_pending_execution")
        if (!decisionId.isNullOrEmpty()) {
            // Clear the extra so it doesn't trigger again
            intent?.removeExtra("widget_pending_execution")
            // Also clear from SharedPreferences
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            prefs.edit().remove("flutter.widget_pending_execution").apply()
            // Notify Flutter to navigate
            widgetChannel?.invokeMethod("navigateToExecute", decisionId)
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
