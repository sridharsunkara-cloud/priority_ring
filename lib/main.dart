import 'package:flutter/material.dart';
import 'core/widgets/responsive_layout.dart';

void main() {
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
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0056D2), // Professional "Safety" Blue
      ),
      home: const ResponsiveLayout(
        mobileBody: Scaffold(body: Center(child: Text("PriorityRing Mobile Active"))),
        desktopBody: Scaffold(body: Center(child: Text("PriorityRing Desktop Active"))),
      ),
    );
  }
}
