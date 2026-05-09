import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/data.dart';
import 'package:uuid/rng.dart';
import 'package:uuid/uuid.dart';

class DeviceIdentityService {
  DeviceIdentityService._();

  static const _storageKey = 'studysync_device_id';
  static const _uuid = Uuid(goptions: GlobalOptions(CryptoRNG()));

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
    return _uuid.v4();
  }
}
