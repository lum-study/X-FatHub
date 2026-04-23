package com.example.xfathub

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.xfathub.ActivityTrackingService

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.xfathub/activity_tracking"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startActivityTracking" -> {
                        val activityId = call.argument<String>("activityId") ?: ""
                        startActivityTracking(activityId)
                        result.success("Started")
                    }
                    "stopActivityTracking" -> {
                        stopActivityTracking()
                        result.success("Stopped")
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startActivityTracking(activityId: String) {
        val intent = Intent(this, ActivityTrackingService::class.java).apply {
            action = "com.example.xfathub.action.START_TRACKING"
            putExtra("activity_id", activityId)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopActivityTracking() {
        val intent = Intent(this, ActivityTrackingService::class.java).apply {
            action = "com.example.xfathub.action.STOP_TRACKING"
        }
        stopService(intent)
    }
}
