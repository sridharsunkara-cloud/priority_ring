import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:alarm/model/notification_settings.dart' as alarm_ns;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_stub.dart' 
  if (dart.library.io) 'notification_mobile.dart'; 

class EscalationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const _platform = MethodChannel('com.priorityring/audio');
  static const int T_STAGE2 = 5;
  static const int T_STAGE3 = 20;
  static Timer? _escalationTimer;
  static int _elapsedSeconds = 0;

  static Future<void> initialize() async {
    // This call is now safe. Chrome uses the stub, Redmi uses the mobile version.
    await NotificationAdapter.initialize(() => stopAll());
  }

  static Future<void> triggerEscalation(String senderName) async {
    _elapsedSeconds = 0;

    // Immediate Stage 1
    await _runStage(1, senderName);

    _escalationTimer?.cancel();
    _escalationTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _elapsedSeconds++;

      if (_elapsedSeconds == T_STAGE2) {
        await _runStage(2, senderName);
      }

      if (_elapsedSeconds == T_STAGE3) {
        await _runStage(3, senderName);
        timer.cancel();
      }
    });
  }

  static Future<void> _runStage(int stage, String senderName) async {
    if (kIsWeb) {
      print('[WEB TEST] Stage $stage triggered for $senderName');
      return; 
    }

    final prefs = await SharedPreferences.getInstance();
    
    if (stage == 3) {
      // Stage 3 (20s): Nuclear Hand-off to Native
      final ringNuclearUri = prefs.getString('ring_nuclear') ?? 'calm_emergency.mp3';
      try {
        await _platform.invokeMethod('startSiren', {'uri': ringNuclearUri});
      } catch (e) {
        print("Failed to trigger native siren: $e");
      }
      return;
    }

    if (stage == 2) {
      // Stage 2 (5s): Persistent Audible Alarm
      final ringAsset = prefs.getString('ring_medium') ?? 'school_warning.wav';
      final alarmSettings = AlarmSettings(
        id: 100,
        dateTime: DateTime.now().add(const Duration(milliseconds: 100)),
        assetAudioPath: 'assets/audio/$ringAsset',
        loopAudio: true,
        vibrate: true,
        volumeSettings: VolumeSettings.fade(
          volume: 0.8,
          fadeDuration: const Duration(seconds: 2),
          volumeEnforced: true,
        ),
        notificationSettings: alarm_ns.NotificationSettings(
          title: 'DRINGEND: $senderName',
          body: 'Bitte reagieren Sie sofort!',
          stopButton: 'Stoppen',
        ),
      );
      await Alarm.set(alarmSettings: alarmSettings);
    }

    // Common Notification Details for Stage 1 & 2
    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        'emergency_channel',
        'Notfall-Alarm',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
      ),
      iOS: const DarwinNotificationDetails(interruptionLevel: InterruptionLevel.critical),
    );

    // FIX: v20+ show() method MUST use NAMED ARGUMENTS
    await _notifications.show(
      id: stage,
      title: stage == 1 ? 'Sanfter Hinweis' : 'Dringender Alarm',
      body: 'Prioritäts-Anruf von: $senderName',
      notificationDetails: details,
    );
  }

  static void stopAll() {
    _escalationTimer?.cancel();
    if (!kIsWeb) {
        _platform.invokeMethod('stopSiren').catchError((_) {});
        _notifications.cancelAll();
        Alarm.stop(100);
    }
  }
}
