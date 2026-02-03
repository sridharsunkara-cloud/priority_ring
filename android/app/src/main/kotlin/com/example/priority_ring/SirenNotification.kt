package com.example.priority_ring

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

object SirenNotification {
    private const val CHANNEL_ID = "priority_ring_alarm"
    private const val NOTIFICATION_ID = 999

    fun show(context: Context) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Priority Ring Alarm",
                NotificationManager.IMPORTANCE_HIGH // MAX is deprecated or same as HIGH usually, HIGH pops up
            ).apply {
                description = "Emergency Siren Notification"
                setSound(null, null) // Managing sound manually via MediaPlayer
            }
            notificationManager.createNotificationChannel(channel)
        }

        val stopIntent = Intent(context, StopSirenReceiver::class.java).apply {
            action = "com.priorityring.STOP_SIREN"
        }
        
        // Android 12+ requires FLAG_IMMUTABLE
        val pendingStopIntent = PendingIntent.getBroadcast(
            context, 
            0, 
            stopIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(context.applicationInfo.icon) // Use app icon or specific drawable
            .setContentTitle("Notfall-Alarm Aktiv")
            .setContentText("STOP zum Beenden")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setOngoing(true)
            .addAction(android.R.drawable.ic_media_pause, "STOP", pendingStopIntent)
            .build()

        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    fun cancel(context: Context) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(NOTIFICATION_ID)
    }
}
