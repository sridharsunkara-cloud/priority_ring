package com.example.priority_ring

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class StopSirenReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "com.priorityring.STOP_SIREN") {
            NativeAlarmPlayer.stop()
            SirenNotification.cancel(context)
        }
    }
}
