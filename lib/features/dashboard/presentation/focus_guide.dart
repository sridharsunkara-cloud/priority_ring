import 'package:flutter/material.dart';

class FocusGuide extends StatelessWidget {
  const FocusGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('iOS Fokus-Optimierung', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Whitelist-Anleitung',
            style: TextStyle(color: Colors.blue, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Folgen Sie diesen Schritten, um sicherzustellen, dass Notrufe auch im Fokus-Modus durchkommen:',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 30),
          _buildStep(
            '1',
            'Öffnen Sie die iOS Einstellungen > Fokus.',
            Icons.settings,
          ),
          _buildStep(
            '2',
            'Wählen Sie Ihren aktiven Fokus (z.B. Arbeiten).',
            Icons.center_focus_strong,
          ),
          _buildStep(
            '3',
            'Tippen Sie auf "Personen" > "Mitteilungen erlauben".',
            Icons.people,
          ),
          _buildStep(
            '4',
            'Fügen Sie die Telefonnummern Ihrer Schule oder Familie hinzu.',
            Icons.add_call,
          ),
          _buildStep(
            '5',
            'Suchen Sie nach der PriorityRing App und erlauben Sie "Kritische Hinweise".',
            Icons.notification_important,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Center(
              child: Text('Verstanden', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.2),
            child: Text(number, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    const Text('Schritt', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
