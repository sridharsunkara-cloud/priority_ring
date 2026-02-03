import 'package:shared_preferences/shared_preferences.dart';

class PriorityContactRepository {
  static const String _storageKey = 'priority_contacts';

  Future<List<String>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_storageKey) ?? [];
  }

  Future<void> addContact(String rawNumber) async {
    final normalized = _normalize(rawNumber);
    if (!_isValid(normalized)) {
      throw const FormatException('Invalid phone number format');
    }

    final prefs = await SharedPreferences.getInstance();
    final contacts = prefs.getStringList(_storageKey) ?? [];

    if (!contacts.contains(normalized)) {
      contacts.add(normalized);
      await prefs.setStringList(_storageKey, contacts);
    }
  }

  Future<void> removeContact(String number) async {
    final prefs = await SharedPreferences.getInstance();
    final contacts = prefs.getStringList(_storageKey) ?? [];
    
    // We normalize here too just in case the UI passes a raw number
    final normalized = _normalize(number);
    
    contacts.remove(normalized);
    await prefs.setStringList(_storageKey, contacts);
  }

  String _normalize(String raw) {
    // Remove spaces, parentheses, dashes
    return raw.replaceAll(RegExp(r'[\s\(\)\-]'), '');
  }

  bool _isValid(String normalized) {
    // Basic E.164-ish check: 6 to 15 digits, optional + prefix
    return RegExp(r'^\+?[0-9]{6,15}$').hasMatch(normalized);
  }
}
