package com.example.priority_ring

import android.app.role.RoleManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.telecom.TelecomManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.priorityring/call_handler"
    private val AUDIO_CHANNEL = "com.priorityring/audio"
    private var callReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "requestCallScreeningRole") {
                requestCallScreeningRole()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startSiren" -> {
                    val uri = call.argument<String>("uri")
                    NativeAlarmPlayer.start(this, uri)
                    result.success(null)
                }
                "stopSiren" -> {
                    NativeAlarmPlayer.stop()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        callReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == "com.priorityring.INCOMING_CALL") {
                    val phoneNumber = intent.getStringExtra("phone_number")
                    if (phoneNumber != null) {
                        // Send to Flutter
                         flutterEngine?.dartExecutor?.binaryMessenger?.let {
                            MethodChannel(it, CHANNEL).invokeMethod("incomingCall", phoneNumber)
                        }
                    }
                }
            }
        }
        
        val filter = IntentFilter("com.priorityring.INCOMING_CALL")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(callReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
             // For older versions, strict export rules might apply, but this is an internal broadcast.
             // However, Context.RECEIVER_NOT_EXPORTED is safer on API 33+ if possible, 
             // but our sender is a Service in the same app.
            registerReceiver(callReceiver, filter)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        callReceiver?.let { unregisterReceiver(it) }
    }

    private fun requestCallScreeningRole() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(ROLE_SERVICE) as RoleManager
            if (roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)) {
                if (!roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)) {
                    val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING)
                    startActivityForResult(intent, 1)
                }
            }
        } else {
            // Fallback or simpler intent for older APIs if applicable, 
            // but CallScreeningService is API 24+, RoleManager is API 29+.
            // Below API 29, the system might handle default dialer/spam apps differently 
            // or use TelecomManager.ACTION_CHANGE_DEFAULT_DIALER
        }
    }
}
