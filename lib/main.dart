import 'package:flutter/material.dart';
import 'core/widgets/responsive_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PriorityRingApp());
}

class PriorityRingApp extends StatelessWidget {
  const PriorityRingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PriorityRing',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueAccent,
      ),
      home: const ResponsiveLayout(
        mobileBody: Scaffold(body: Center(child: Text("Mobile View Active"))),
        desktopBody: Scaffold(body: Center(child: Text("Desktop View Active"))),
      ),
    );
  }
}
