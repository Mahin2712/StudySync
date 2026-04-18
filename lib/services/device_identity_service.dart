import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdentityService {
  DeviceIdentityService._();

  static const _storageKey = 'studysync_device_id';
  static final Random _random = Random.secure();

  static Future<void> ensureInitialized() async {
    await getDeviceId();
  }

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_storageKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final deviceId = _generateUuidV4();
    await prefs.setString(_storageKey, deviceId);
    return deviceId;
  }

  static String _generateUuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int value) => value.toRadixString(16).padLeft(2, '0');

    return [
      for (int i = 0; i < 16; i++) hex(bytes[i]),
    ].join().replaceFirstMapped(
      RegExp(r'^(.{8})(.{4})(.{4})(.{4})(.{12})$'),
      (match) => '${match[1]}-${match[2]}-${match[3]}-${match[4]}-${match[5]}',
    );
  }
}
