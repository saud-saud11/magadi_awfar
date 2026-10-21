import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// A random guest capability, never a shared session or timestamp-based identifier.
class DeviceIdentity {
  static Future<String>? _pending;
  static Future<String> get id => _pending ??= _load();
  static Future<String> _load() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'magadi_guest_capability_v2';
    final saved = prefs.getString(key);
    if (saved != null && RegExp(r'^[a-f0-9]{64}$').hasMatch(saved)) {
      return saved;
    }
    final random = Random.secure();
    final token = List.generate(
      32,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await prefs.setString(key, token);
    return token;
  }

  static Future<Map<String, String>> get headers async => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${await id}',
  };
}
