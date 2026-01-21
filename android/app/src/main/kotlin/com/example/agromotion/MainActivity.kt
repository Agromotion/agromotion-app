// android/app/src/main/kotlin/com/example/agromotion/MainActivity.kt
package com.example.agromotion

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.content.Intent
import android.appwidget.AppWidgetManager
import android.content.ComponentName

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.agromotion/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateWidget" -> {
                        try {
                            val battery = call.argument<Int>("battery") ?: 0
                            val food = call.argument<Int>("food") ?: 0
                            val foodKg = call.argument<Int>("foodKg") ?: 0

                            // Salva os dados
                            val prefs = applicationContext.getSharedPreferences(
                                "robot_data",
                                Context.MODE_PRIVATE
                            )
                            prefs.edit().apply {
                                putInt("battery", battery)
                                putInt("food", food)
                                putInt("foodKg", foodKg)
                                apply()
                            }

                            // Força update dos widgets
                            updateWidget(RobotWidgetBars::class.java)
                            updateWidget(RobotWidgetCircles::class.java)

                            result.success(true)
                        } catch (e: Exception) {
                            result.error("UPDATE_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun updateWidget(widgetClass: Class<*>) {
        val intent = Intent(applicationContext, widgetClass)
        intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        
        val ids = AppWidgetManager.getInstance(applicationContext)
            .getAppWidgetIds(
                ComponentName(applicationContext, widgetClass)
            )
        
        intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        applicationContext.sendBroadcast(intent)
    }
}