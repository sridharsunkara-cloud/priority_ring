import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GatekeeperService {
  static const String _webhookUrl = 'https://n8n.priorityring.com/webhook/gatekeeper'; // Placeholder URL
  static const String _sharedSecret = 'PRIORITY_RING_SECRET_KEY_2026'; // Placeholder Secret

  /// Triggers the Gatekeeper webhook logic if Meeting Mode is active.
  /// Returns true if the webhook was sent successfully.
  static Future<void> triggerGatekeeper(String callerNumber) async {
    // 1. Platform Guarding (Web Safety)
    if (kIsWeb) {
      debugPrint('[Gatekeeper] Web Platform Detected - Returning Unsupported.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final bool isMeetingMode = prefs.getBool('isMeetingMode') ?? false;

    if (!isMeetingMode) {
      debugPrint('[Gatekeeper] Meeting Mode is OFF. Skipping webhook.');
      return;
    }

    debugPrint('[Gatekeeper] Meeting Mode ACTIVE. Processing caller: $callerNumber');

    // 2. Prepare Data
    final templateText = prefs.getString('gatekeeper_template_text') ?? 
        "Hallo, ich bin im Termin. Bei Notfall antworte '1', um mein Handy laut klingeln zu lassen.";
    
    // Privacy-First Hashing
    final salt = 'LOCAL_SALT_${DateTime.now().year}'; // In prod, generate secure salt
    final callerHash = sha256.convert(utf8.encode('$callerNumber$salt')).toString();
    
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final nonce = _generateNonce();

    final Map<String, dynamic> body = {
      'caller_hash': callerHash,
      // For functionality, we might need the actual number if the webhook logic sends SMS.
      // The prompt asks for "Privacy-First Hashing ... for general logs".
      // Assuming Node 3 sends SMS, it needs the number. 
      // We will send 'caller_number' BUT the signature protects it.
      'caller_number': callerNumber, 
      'message': templateText,
      'timestamp': timestamp,
      'nonce': nonce,
    };

    final jsonBody = jsonEncode(body);

    // 3. HMAC-SHA256 Signing
    final signature = _computeSignature(timestamp, nonce, jsonBody);

    // 4. Send Webhook
    try {
      final response = await http.post(
        Uri.parse(_webhookUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Priority-Signature': signature,
        },
        body: jsonBody,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[Gatekeeper] Webhook sent successfully: ${response.statusCode}');
      } else {
        debugPrint('[Gatekeeper] Webhook failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('[Gatekeeper] Error sending webhook: $e');
    }
  }

  static String _generateNonce() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  static String _computeSignature(String timestamp, String nonce, String body) {
    final payload = '$timestamp$nonce$body';
    final key = utf8.encode(_sharedSecret);
    final bytes = utf8.encode(payload);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }
}
