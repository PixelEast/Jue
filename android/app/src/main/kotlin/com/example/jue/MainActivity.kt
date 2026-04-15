package com.example.jue

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.setBackgroundDrawableResource(android.R.color.white)
        window.decorView.setBackgroundColor(Color.WHITE)
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT // 设置为透明
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
            window.isStatusBarContrastEnforced = false
        }
        
        // Additional settings for better compatibility with gesture navigation
        window.decorView.systemUiVisibility = (window.decorView.systemUiVisibility
            or android.view.View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR
            or android.view.View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR)
    }
}
