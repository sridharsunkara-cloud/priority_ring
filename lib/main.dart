import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:alarm/model/notification_settings.dart' as alarm_ns;
import 'package:priority_ring/core/services/escalation_service.dart';
import 'package:priority_ring/features/dashboard/presentation/reliability_dashboard.dart';
import 'package:priority_ring/features/contacts/presentation/priority_contacts_screen.dart';
import 'package:priority_ring/features/onboarding/presentation/trust_simulator_screen.dart';

// 1. MUST be a top-level function (outside any class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.data['type'] == 'RING') {
    final sender = message.data['sender'] ?? 'Cloud Trigger';
    await EscalationService.triggerEscalation(sender);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase
  await Firebase.initializeApp();
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    criticalAlert: true,
  );

  // 3. Register the background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Alarm.init();
  await EscalationService.initialize();

  // 4. Retrieve FCM Token
  try {
    String? token = await FirebaseMessaging.instance.getToken();
    debugPrint("\n--------------------------------------------------------------");
    debugPrint("🔑 YOUR FCM TOKEN: $token");
    debugPrint("--------------------------------------------------------------\n");
  } catch (e) {
    debugPrint("Error retrieving FCM Token: $e");
  }

  runApp(const PriorityRingApp());
}

class PriorityRingApp extends StatelessWidget {
  const PriorityRingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PriorityRing',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
          surface: Colors.black,
        ),
      ),
      home: const ReliabilityDashboard(),
      routes: {
        '/contacts': (context) => const PriorityContactsScreen(),
        '/trust': (context) => const TrustSimulatorScreen(),
      },
    );
  }
}
