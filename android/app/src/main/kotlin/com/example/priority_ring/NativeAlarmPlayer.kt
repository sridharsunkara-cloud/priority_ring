package com.example.priority_ring

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.util.Log

object NativeAlarmPlayer {
    private var mediaPlayer: MediaPlayer? = null

    fun start(context: Context, customUri: String? = null) {
        if (mediaPlayer?.isPlaying == true) return

        stop() // Release any previous instance

        try {
            Log.d("PriorityRing", "🚨 NativeAlarmPlayer: Starting siren ($customUri)...")

            // 1. "Silent" Audio Stream Fix - Force volume to 100%
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            audioManager.setStreamVolume(
                AudioManager.STREAM_ALARM,
                audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM),
                0
            )

            // 2. Determine Audio Source
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                
                if (!customUri.isNullOrEmpty() && customUri.contains("://")) {
                    setDataSource(context, Uri.parse(customUri))
                } else {
                    // Fallback to bundled asset
                    // In a real app, you'd ensure calm_emergency exists in res/raw
                    val resId = context.resources.getIdentifier("calm_emergency", "raw", context.packageName)
                    if (resId != 0) {
                        val assetUri = Uri.parse("android.resource://${context.packageName}/$resId")
                        setDataSource(context, assetUri)
                    } else {
                        // Extreme fallback to emergency_siren
                        val fallbackId = R.raw.emergency_siren
                        val fallbackUri = Uri.parse("android.resource://${context.packageName}/$fallbackId")
                        setDataSource(context, fallbackUri)
                    }
                }
                
                isLooping = true
                prepare()
                start()
            }
            Log.d("PriorityRing", "🚨 NativeAlarmPlayer: Siren is now playing.")
        } catch (e: Exception) {
            Log.e("PriorityRing", "❌ NativeAlarmPlayer Error: ${e.message}")
            e.printStackTrace()
        }
    }

    fun stop() {
        if (mediaPlayer != null) {
            Log.d("PriorityRing", "🛑 NativeAlarmPlayer: Stopping siren.")
            mediaPlayer?.stop()
            mediaPlayer?.release()
            mediaPlayer = null
        }
    }
}
