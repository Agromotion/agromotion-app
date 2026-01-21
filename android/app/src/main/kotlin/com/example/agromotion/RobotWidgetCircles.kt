// android/app/src/main/kotlin/com/example/agromotion/RobotWidgetCircles.kt
package com.example.agromotion

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.RemoteViews
import android.content.res.ColorStateList
import android.os.Build

class RobotWidgetCircles : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_layout_circles)

        // 1. Click to open App
        val intent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                PendingIntent.FLAG_IMMUTABLE
            else
                0
        )
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        // 2. Get robot data from SharedPreferences
        val prefs = context.getSharedPreferences("robot_data", Context.MODE_PRIVATE)
        val battery = prefs.getInt("battery", 85)
        val food = prefs.getInt("food", 62)
        val foodKg = prefs.getInt("foodKg", 62)

        // 3. Update Battery with dynamic color
        val batteryColor = getBatteryColor(battery, context)
        updateProgressColor(views, R.id.circle_battery, batteryColor)
        views.setProgressBar(R.id.circle_battery, 100, battery, false)
        views.setTextViewText(R.id.text_circle_bat, "$battery%")

        // 4. Update Food
        val foodColor = context.getColor(R.color.food_color)
        updateProgressColor(views, R.id.circle_food, foodColor)
        views.setProgressBar(R.id.circle_food, 100, food, false)
        views.setTextViewText(R.id.text_circle_food, "${foodKg}kg")

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun getBatteryColor(battery: Int, context: Context): Int {
        return when {
            battery > 60 -> context.getColor(R.color.battery_high)
            battery > 40 -> context.getColor(R.color.battery_medium)
            battery > 20 -> context.getColor(R.color.battery_low)
            else -> context.getColor(R.color.battery_critical)
        }
    }

    private fun updateProgressColor(views: RemoteViews, viewId: Int, color: Int) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                views.setColorStateList(
                    viewId,
                    "setProgressTintList",
                    ColorStateList.valueOf(color)
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                views.setInt(viewId, "setProgressTintList", color)
            }
        } catch (e: Exception) {
            android.util.Log.e("RobotWidgetCircles", "Erro ao aplicar cor: ${e.message}")
        }
    }
}