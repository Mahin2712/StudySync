import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studysync/services/device_identity_service.dart';
import 'package:uuid/validation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceIdentityService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('getDeviceId generates a valid UUID v4', () async {
      final deviceId = await DeviceIdentityService.getDeviceId();

      expect(deviceId, isNotEmpty);
      expect(UuidValidation.isValidUUID(fromString: deviceId), isTrue);

      // UUID v4 regex check (redundant but explicit as per plan)
      final uuidV4Regex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      expect(uuidV4Regex.hasMatch(deviceId), isTrue);
    });

    test('getDeviceId persists and returns the same ID', () async {
      final id1 = await DeviceIdentityService.getDeviceId();
      final id2 = await DeviceIdentityService.getDeviceId();

      expect(id1, equals(id2));
    });

    test('getDeviceId respects existing ID in SharedPreferences', () async {
      const existingId = 'existing-test-id-123';
      SharedPreferences.setMockInitialValues({
        'studysync_device_id': existingId,
      });

      final deviceId = await DeviceIdentityService.getDeviceId();
      expect(deviceId, equals(existingId));
    });

    test('Collision check: generates 1000 unique UUIDs', () async {
      final generatedIds = <String>{};
      const count = 1000;

      for (var i = 0; i < count; i++) {
        // We need to clear SharedPreferences to force generation of a new ID
        // OR we just test the internal generator if it were accessible.
        // Since _generateUuidV4 is private, we'll mock SharedPreferences for each iteration.
        SharedPreferences.setMockInitialValues({});
        final id = await DeviceIdentityService.getDeviceId();
        generatedIds.add(id);
      }

      expect(generatedIds.length, equals(count));
    });
  });
}
