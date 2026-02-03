import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';

class TrustSimulatorScreen extends StatefulWidget {
  const TrustSimulatorScreen({super.key});

  @override
  State<TrustSimulatorScreen> createState() => _TrustSimulatorScreenState();
}

class _TrustSimulatorScreenState extends State<TrustSimulatorScreen> {
  bool isRinging = false;

  @override
  void initState() {
    super.initState();
    // Listen to alarm ring state
    // Using Alarm.ringing as requested and per v5 API
    // Use .stream for StreamController and .id for AlarmSettings
    Alarm.ringStream.stream.listen((alarmSettings) {
      if (alarmSettings.id == 42) {
        debugPrint("Siren is ringing! Trust verified.");
        setState(() {
          isRinging = true;
        });
      }
    });
  }

  Future<void> _triggerAlarm() async {
    final alarmSettings = AlarmSettings(
      id: 42,
      dateTime: DateTime.now().add(const Duration(seconds: 2)),
      assetAudioPath: 'assets/audio/emergency_siren.wav',
      loopAudio: true,
      vibrate: true,
      volumeSettings: VolumeSettings.fade(
        volume: 1.0,
        fadeDuration: const Duration(seconds: 3),
        volumeEnforced: true,
      ),
      notificationSettings: const NotificationSettings(
        title: 'Emergency Siren',
        body: 'This is a test alarm',
        stopButton: 'Stop',
      ),
      androidFullScreenIntent: true,
    );

    await Alarm.set(alarmSettings: alarmSettings);
  }

  Future<void> _stopAlarm() async {
    await Alarm.stop(42);
    setState(() {
      isRinging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0056D2), // Safety Blue
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _triggerAlarm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              child: const Text('TEST EMERGENCY SIREN'),
            ),
            if (isRinging) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _stopAlarm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                child: const Text('STOP SIREN'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
