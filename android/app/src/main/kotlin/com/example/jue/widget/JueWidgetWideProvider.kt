package com.example.jue.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.example.jue.R

class JueWidgetWideProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_UPDATE) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, JueWidgetWideProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }

    companion object {
        const val ACTION_UPDATE = "com.example.jue.ACTION_UPDATE_WIDGET_WIDE"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val decisionId = prefs.getString("widget_decision_id", null)
            val decisionTheme = prefs.getString("widget_decision_theme", null)

            val isBound = decisionId != null && decisionTheme != null
            val title = if (isBound) decisionTheme else "未绑定决定"
            val subtitle = if (isBound) "\u201c\u7531\u903b\u8f91 \u7ec8\u7ed3\u7ea0\u7ed3.\u201d" else "请在App中绑定决定"

            val views = RemoteViews(context.packageName, R.layout.jue_widget_wide)

            views.setTextViewText(R.id.widget_title, title)
            views.setTextViewText(R.id.widget_subtitle, subtitle)
            views.setTextViewText(R.id.widget_button_text, if (isBound) "即刻判决" else "打开决App")

            val clickIntent = Intent(context, JueWidgetClickReceiver::class.java).apply {
                action = "com.example.jue.WIDGET_CLICK"
                putExtra("decision_id", decisionId ?: "")
                putExtra("app_widget_id", appWidgetId)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                appWidgetId + 10000,
                clickIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
