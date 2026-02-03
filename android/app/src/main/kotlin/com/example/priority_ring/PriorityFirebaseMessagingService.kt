package com.example.priority_ring // Adjusted to match your project's namespace

import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class PriorityFirebaseMessagingService : FirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        Log.d("SirenTest", "☁️ Message Received from Cloud!")

        // Check if message contains a data payload
        if (remoteMessage.data.isNotEmpty()) {
            val type = remoteMessage.data["type"]
            
            if (type == "RING") {
                Log.d("SirenTest", "🚨 TRIGGERING SIREN NOW...")
                // This calls your existing NativeAlarmPlayer code
                NativeAlarmPlayer.start(applicationContext)
            }
        }
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d("SirenTest", "🔑 New FCM Token: $token")
    }
}
