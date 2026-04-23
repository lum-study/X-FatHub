package com.example.xfathub

import android.app.Notification
import android.app.Service
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat

/// Foreground Service for continuous activity tracking in background
/// This service keeps the app alive and ensures location updates continue
/// even when the screen is locked or the app is in the background
class ActivityTrackingService : Service() {
    companion object {
        private const val CHANNEL_ID = "activity_tracking_channel"
        private const val NOTIFICATION_ID = 42
        private const val ACTION_START = "com.example.xfathub.action.START_TRACKING"
        private const val ACTION_STOP = "com.example.xfathub.action.STOP_TRACKING"
        private const val ACTIVITY_ID = "activity_id"
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val activityId = intent.getStringExtra(ACTIVITY_ID) ?: ""
                startActivityTracking(activityId)
            }
            ACTION_STOP -> {
                stopActivityTracking()
            }
            else -> {
                // Default start
                startActivityTracking("")
            }
        }
        return START_STICKY
    }

    private fun startActivityTracking(activityId: String) {
        // Create notification channel for foreground service
        createNotificationChannel()

        // Create notification for foreground service
        val notification = createNotification(activityId)

        // Start foreground service with notification
        // This keeps the service alive and notifies the user about the activity
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        println("✓ Activity tracking foreground service started: $activityId")
    }

    private fun stopActivityTracking() {
        // Stop the foreground service
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        stopSelf()
        println("⏹ Activity tracking foreground service stopped")
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, "Activity Tracking", importance)
            channel.description = "Tracks your activity in the background"
            channel.setShowBadge(true)

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(activityId: String): Notification {
        // Create intent to open app when notification is tapped
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(ACTIVITY_ID, activityId)
        }

        val pendingIntent: PendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        } else {
            @Suppress("DEPRECATION")
            PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT)
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("XFatHub Activity Tracking")
            .setContentText("Tracking your activity in progress...")
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setContentIntent(pendingIntent)
            .setOngoing(true) // Prevent user from swiping away
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setAutoCancel(false)
            .build()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        println("⏹ Activity tracking service destroyed")
    }
}
