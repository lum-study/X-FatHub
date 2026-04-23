package com.example.xfathub

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.xfathub.ActivityTrackingService

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.xfathub/activity_tracking"
    private val DEEP_LINK_CHANNEL = "com.example.xfathub/deep_link"
    private var deepLinkMethodChannel: MethodChannel? = null

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // Handle deep link when app is already running
        handleDeepLink(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Activity tracking method channel
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

        // Deep link method channel
        deepLinkMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEEP_LINK_CHANNEL)
        
        // Handle deep link when app is launched from shortcut
        handleDeepLink(intent)
    }

    private fun handleDeepLink(intent: Intent) {
        val data = intent.data
        if (data != null && data.scheme == "xfathub") {
            val host = data.host
            println("🔗 Deep link detected: $host")
            
            // Send the deep link route to Flutter
            deepLinkMethodChannel?.invokeMethod("navigate", mapOf("route" to "/$host"))
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
