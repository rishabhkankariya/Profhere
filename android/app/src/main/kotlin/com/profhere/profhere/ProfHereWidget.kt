package com.profhere.profhere

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

class ProfHereWidget : HomeWidgetProvider() {

    companion object {
        const val ACTION_STATUS = "com.profhere.profhere.ACTION_STATUS"
        const val EXTRA_STATUS  = "status_value"
        const val EXTRA_LABEL   = "status_label"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_STATUS) {
            val statusValue = intent.getStringExtra(EXTRA_STATUS) ?: return
            val statusLabel = intent.getStringExtra(EXTRA_LABEL) ?: statusValue

            HomeWidgetPlugin.getData(context)
                .edit()
                .putString("faculty_status", statusLabel)
                .apply()

            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, ProfHereWidget::class.java))
            val prefs = HomeWidgetPlugin.getData(context)
            for (id in ids) updateWidget(context, manager, id, prefs)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        widgetData: SharedPreferences,
    ) {
        try {
            val isLoggedIn  = widgetData.getString("faculty_logged_in", "false") == "true"
            val facultyName = widgetData.getString("faculty_name", "Not logged in") ?: "Not logged in"
            val status      = widgetData.getString("faculty_status", "--") ?: "--"

            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            views.setTextViewText(R.id.widget_faculty_name, facultyName)
            views.setTextViewText(R.id.widget_status, status)
            views.setTextViewText(
                R.id.widget_login_status,
                if (isLoggedIn) "Online" else "Offline"
            )
            views.setTextColor(
                R.id.widget_login_status,
                if (isLoggedIn) Color.parseColor("#16A34A") else Color.parseColor("#94A3B8")
            )

            // All 5 status buttons — broadcast only, no app opens
            views.setOnClickPendingIntent(R.id.btn_available,
                buildBroadcast(context, "available", "Available", 1))
            views.setOnClickPendingIntent(R.id.btn_busy,
                buildBroadcast(context, "busy", "Busy", 2))
            views.setOnClickPendingIntent(R.id.btn_lecture,
                buildBroadcast(context, "inLecture", "In Lecture", 3))
            views.setOnClickPendingIntent(R.id.btn_meeting,
                buildBroadcast(context, "meeting", "In Meeting", 4))
            views.setOnClickPendingIntent(R.id.btn_away,
                buildBroadcast(context, "away", "Away", 5))

            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun buildBroadcast(
        context: Context,
        statusValue: String,
        statusLabel: String,
        requestCode: Int,
    ): PendingIntent {
        val intent = Intent(context, ProfHereWidget::class.java).apply {
            action = ACTION_STATUS
            putExtra(EXTRA_STATUS, statusValue)
            putExtra(EXTRA_LABEL, statusLabel)
        }
        return PendingIntent.getBroadcast(
            context, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
