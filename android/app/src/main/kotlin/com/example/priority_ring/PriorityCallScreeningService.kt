package com.example.priority_ring

import android.content.Context
import android.content.Intent
import android.telecom.Call
import android.telecom.CallScreeningService
import android.util.Log
import org.json.JSONArray

class PriorityCallScreeningService : CallScreeningService() {

    override fun onScreenCall(callDetails: Call.Details) {
        val phoneNumber = getPhoneNumber(callDetails)
        val normalizedNumber = normalizePhoneDe(phoneNumber)
        
        Log.d("PriorityRing", "Incoming RAW: $phoneNumber | Norm: $normalizedNumber")

        // 1. Immediately allow the call to proceed (UI/System)
        val response = CallResponse.Builder()
            .setDisallowCall(false)
            .setRejectCall(false)
            .setSkipCallLog(false)
            .setSkipNotification(false)
            .build()
        
        respondToCall(callDetails, response)

        // 2. NUCLEAR FALLBACK: Trigger Siren if Priority Contact
        if (normalizedNumber.isNotEmpty()) {
            if (isPriorityContact(normalizedNumber)) {
                Log.d("PriorityRing", "🚨 MATCH FOUND! Triggering Siren Escalation.")
                
                // Read user-selected ringtone for Tier A Native Hand-off
                val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val ringNuclearUri = prefs.getString("flutter.ring_nuclear", null)

                NativeAlarmPlayer.start(this, ringNuclearUri)
                SirenNotification.show(this)
            }

            // 3. Broadcast to Flutter for UI logic
            val intent = Intent("com.priorityring.INCOMING_CALL")
            intent.putExtra("phone_number", normalizedNumber)
            sendBroadcast(intent)
        }
    }

    private fun getPhoneNumber(callDetails: Call.Details): String? {
        return callDetails.handle?.schemeSpecificPart
    }

    /**
     * GERMANY-PROOF NORMALIZATION (Universal Reliability Blueprint)
     * Handles: +49, 0049, local 0, and dialable formatting.
     */
    private fun normalizePhoneDe(number: String?): String {
        if (number.isNullOrEmpty()) return ""
        
        // Remove non-numeric characters (keep +)
        var s = number.replace(Regex("[^0-9+]"), "")

        // Handle 00 -> +
        if (s.startsWith("00")) {
            s = "+" + s.substring(2)
        }

        // DE Rule: Leading 0 followed by non-0 -> +49
        if (s.startsWith("0") && !s.startsWith("00")) {
             s = "+49" + s.substring(1)
        }
        
        return s
    }

    private fun isPriorityContact(incomingNormalized: String): Boolean {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val jsonString = prefs.getString("flutter.priority_contacts", null) ?: return false
            
            val jsonArray = JSONArray(jsonString)
            for (i in 0 until jsonArray.length()) {
                val savedNumber = jsonArray.getString(i)
                if (normalizePhoneDe(savedNumber) == incomingNormalized) {
                    return true
                }
            }
        } catch (e: Exception) {
            Log.e("PriorityRing", "Error parsing priority contacts: ${e.message}")
        }
        return false
    }
}
