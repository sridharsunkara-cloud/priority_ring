import 'package:flutter/material.dart';
import 'package:priority_ring/core/services/gatekeeper_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class ReliabilityDashboard extends StatefulWidget {
  const ReliabilityDashboard({super.key});

  @override
  State<ReliabilityDashboard> createState() => _ReliabilityDashboardState();
}

class _ReliabilityDashboardState extends State<ReliabilityDashboard> {
  bool _callScreeningOk = false;
  bool _batteryOptimOk = false;
  bool _fsiOk = false;
  
  bool _isMeetingMode = false;
  final TextEditingController _templateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _loadGatekeeperSettings();
  }

  Future<void> _checkStatus() async {
    // Tier A: Call Screening (Simplified for demo, would use MethodChannel in prod)
    final callScreenStatus = await Permission.phone.isGranted;
    
    // Tier B: Battery & Full Screen Intent
    final batteryOptim = await Permission.ignoreBatteryOptimizations.isGranted;
    
    setState(() {
      _callScreeningOk = callScreenStatus;
      _batteryOptimOk = batteryOptim;
      _fsiOk = true; // Placeholder for FSI check
    });
  }

  Future<void> _loadGatekeeperSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isMeetingMode = prefs.getBool('isMeetingMode') ?? false;
      _templateController.text = prefs.getString('gatekeeper_template_text') ?? 
          "Hallo, ich bin im Termin. Bei Notfall antworte '1', um mein Handy laut klingeln zu lassen.";
    });
  }

  Future<void> _toggleMeetingMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMeetingMode', value);
    setState(() {
      _isMeetingMode = value;
    });
  }

  Future<void> _saveTemplate(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gatekeeper_template_text', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // OLED Optimized
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Reliability Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _checkStatus,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             _buildSectionHeader('Gatekeeper (n8n Integration)'),
             SwitchListTile(
              title: const Text('Meeting Modus', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Automatische Antwort + Webhook Trigger', style: TextStyle(color: Colors.grey)),
              value: _isMeetingMode,
              activeColor: Colors.blue,
              contentPadding: EdgeInsets.zero,
              onChanged: _toggleMeetingMode,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _templateController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Auto-Reply Vorlage',
                labelStyle: TextStyle(color: Colors.blue),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
              ),
              maxLines: 2,
              onChanged: _saveTemplate,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.webhook),
              label: const Text('Test Webhook (Mock)'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              onPressed: () async {
                await GatekeeperService.triggerGatekeeper('TEST-NUMBER-12345');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Webhook Trigger gesendet!')),
                  );
                }
              },
            ),
            const SizedBox(height: 30),

            _buildSectionHeader('System-Status'),
            _buildStatusCard(
              title: 'System-Level Schutz',
              subtitle: 'Tier A: Android ROLE_CALL_SCREENING',
              status: _callScreeningOk,
              description: 'Ermöglicht das automatische Abfangen von Notrufen.',
            ),
            const SizedBox(height: 15),
            _buildStatusCard(
              title: 'Erweiterter Schutz',
              subtitle: 'Tier B: Battery & Full Screen',
              status: _batteryOptimOk,
              description: 'Garantiert Alarm-Wiedergabe auch im Standby-Modus.',
            ),
            const SizedBox(height: 15),
            _buildStatusCard(
              title: 'Fokus-Optimierung',
              subtitle: 'Tier C: iOS Critical Alerts',
              status: _fsiOk,
              description: 'Umgeht den Nicht-Stören-Modus bei Notfällen.',
            ),
            const SizedBox(height: 30),
            
            _buildSectionHeader('Klingelton Einstellungen'),
            const SizedBox(height: 10),
            _buildRingtoneTile('Sanfter Alarm (Prio 1)', 'ring_soft', 'night_soft.mp3'),
            _buildRingtoneTile('Warnung (Prio 2)', 'ring_medium', 'school_warning.wav'),
            _buildRingtoneTile('Notfall-Sirene (Prio 3)', 'ring_nuclear', 'calm_emergency.mp3'),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String subtitle,
    required bool status,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Icon(
                status ? Icons.check_circle : Icons.error,
                color: status ? Colors.green : Colors.red,
              ),
            ],
          ),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(color: Colors.grey[300], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRingtoneTile(String label, String key, String defaultValue) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(color: Colors.white)),
      subtitle: Text(defaultValue, style: TextStyle(color: Colors.grey[500])),
      trailing: const Icon(Icons.music_note, color: Colors.blue),
      onTap: () async {
        // In a real app, this would open a file picker
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, defaultValue);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label gespeichert')),
        );
      },
    );
  }
}
