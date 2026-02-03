import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../../core/data/priority_contact_repository.dart';

class PriorityContactsScreen extends StatefulWidget {
  const PriorityContactsScreen({super.key});

  @override
  State<PriorityContactsScreen> createState() => _PriorityContactsScreenState();
}

class _PriorityContactsScreenState extends State<PriorityContactsScreen> {
  final PriorityContactRepository _repository = PriorityContactRepository();
  static const platform = MethodChannel('com.priorityring/call_handler');
  List<String> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await _repository.getContacts();
    setState(() {
      _contacts = contacts;
      _isLoading = false;
    });
  }

  Future<void> _requestRole() async {
    // Show explanation dialog first
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sicherheit geht vor'),
        content: const Text(
          'Damit PriorityRing im Notfall klingelt, muss die App als Anrufer-ID-App festgelegt werden. Sie müssen auch Benachrichtigungen zulassen, damit Sie den Alarm stoppen können.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Weiter'),
          ),
        ],
      ),
    );

    if (shouldProceed == true) {
      try {
        // Request Notification Permission (Android 13+)
        await Permission.notification.request();

        await platform.invokeMethod('requestCallScreeningRole');
      } on PlatformException catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler: ${e.message}')),
          );
        }
      }
    }
  }

  Future<void> _addContact(String number) async {
    try {
      await _repository.addContact(number);
      _loadContacts();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Error handling is done inside the dialog's StatefulBuilder
      rethrow;
    }
  }

  Future<void> _removeContact(String number) async {
    await _repository.removeContact(number);
    _loadContacts();
  }

  void _showAddContactDialog() {
    String number = '';
    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Priority Contact'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'z.B. +49 170 1234567',
                      errorText: errorText,
                    ),
                    keyboardType: TextInputType.phone,
                    onChanged: (value) {
                      number = value;
                      if (errorText != null) {
                        setDialogState(() {
                          errorText = null;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Auto-convert to German format (+49)
                    String cleaned = number.replaceAll(RegExp(r'[\s\(\)\-]'), '');
                    
                    if (cleaned.startsWith('00')) {
                      cleaned = '+${cleaned.substring(2)}';
                    } else if (cleaned.startsWith('0')) {
                      cleaned = '+49${cleaned.substring(1)}';
                    }

                    // Validate
                    if (!RegExp(r'^\+\d+$').hasMatch(cleaned)) {
                       setDialogState(() {
                          errorText = 'Nummer muss mit + beginnen (z.B. +49...)';
                        });
                        return;
                    }

                    try {
                      await _addContact(cleaned);
                    } catch (e) {
                         setDialogState(() {
                          errorText = 'Fehler beim Speichern';
                        });
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Priority Contacts'),
        backgroundColor: const Color(0xFF0056D2), // Safety Blue
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'FCM Token kopieren',
            onPressed: () async {
              try {
                final token = await FirebaseMessaging.instance.getToken();
                if (token != null) {
                  print("FCM Token: $token");
                  if (context.mounted) {
                    await Clipboard.setData(ClipboardData(text: token));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Token in die Zwischenablage kopiert!')),
                    );
                  }
                } else {
                   if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kein Token erhalten.')),
                    );
                  }
                }
              } catch (e) {
                print("Error getting token: $e");
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.shield),
            tooltip: 'Schutz aktivieren',
            onPressed: _requestRole,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? const Center(
                  child: Text(
                    'No priority contacts added yet.\nTap + to add one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  itemCount: _contacts.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    return ListTile(
                      leading: const Icon(Icons.phone_iphone, color: Color(0xFF0056D2)),
                      title: Text(
                        contact,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeContact(contact),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactDialog,
        backgroundColor: const Color(0xFF0056D2),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
