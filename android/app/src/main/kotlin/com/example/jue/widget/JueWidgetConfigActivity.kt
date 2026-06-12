package com.example.jue.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

class JueWidgetConfigActivity : android.app.Activity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finishWithCancel()
            return
        }

        setResult(RESULT_CANCELED, Intent().apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        })

        showDecisionPicker()
    }

    private fun showDecisionPicker() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val decisions = mutableListOf<Pair<String, String>>()

        // Method 1: getString (JSON array format - most common)
        try {
            var jsonString = prefs.getString("flutter.decisions", null)
            Log.d("JueWidget", "String result: ${jsonString?.take(200)}")
            if (jsonString != null) {
                // shared_preferences prefixes StringList with a base64 marker + "!"
                val delimiterIndex = jsonString.indexOf("![")
                if (delimiterIndex != -1) {
                    jsonString = jsonString.substring(delimiterIndex + 1)
                }
                val jsonArray = JSONArray(jsonString)
                for (i in 0 until jsonArray.length()) {
                    val item = jsonArray.getString(i)
                    parseDecisionItem(item)?.let { decisions.add(it) }
                }
            }
        } catch (e: Exception) {
            Log.e("JueWidget", "getString parse error: $e")
        }

        // Method 2: If getString failed, try getStringSet
        if (decisions.isEmpty()) {
            try {
                val stringSet = prefs.getStringSet("flutter.decisions", null)
                Log.d("JueWidget", "StringSet result: $stringSet")
                if (stringSet != null) {
                    for (item in stringSet) {
                        parseDecisionItem(item)?.let { decisions.add(it) }
                    }
                }
            } catch (e: Exception) {
                Log.e("JueWidget", "getStringSet error: $e")
            }
        }

        Log.d("JueWidget", "Parsed decisions: ${decisions.map { it.second }}")

        if (decisions.isEmpty()) {
            android.app.AlertDialog.Builder(this)
                .setTitle("暂无决定")
                .setMessage("请先在决App中创建一个决定，再来添加小组件。")
                .setPositiveButton("确定") { _, _ -> finishWithCancel() }
                .setOnCancelListener { finishWithCancel() }
                .show()
            return
        }

        val builder = android.app.AlertDialog.Builder(this)
        builder.setTitle("选择要绑定的决定")
        builder.setCancelable(true)

        val items = decisions.map { it.second }.toTypedArray()
        builder.setItems(items) { _, which ->
            val (id, theme) = decisions[which]

            val homeWidgetPrefs = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            homeWidgetPrefs.edit()
                .putString("widget_${appWidgetId}_decision_id", id)
                .putString("widget_${appWidgetId}_decision_theme", theme)
                .apply()

            val appWidgetManager = AppWidgetManager.getInstance(this)
            JueWidgetProvider.updateAppWidget(this, appWidgetManager, appWidgetId)

            setResult(RESULT_OK, Intent().apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            })
            finish()
        }

        builder.setOnCancelListener { finishWithCancel() }
        builder.show()
    }

    private fun parseDecisionItem(item: String): Pair<String, String>? {
        return try {
            val obj = JSONObject(item)
            val id = obj.optString("id", "")
            val theme = obj.optString("theme", "")
            val isDraft = obj.optBoolean("isDraft", false)
            if (id.isNotEmpty() && theme.isNotEmpty() && !isDraft) {
                id to theme
            } else null
        } catch (e: Exception) {
            Log.e("JueWidget", "Parse item error: $e")
            null
        }
    }

    private fun finishWithCancel() {
        setResult(RESULT_CANCELED, Intent().apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        })
        finish()
    }
}
