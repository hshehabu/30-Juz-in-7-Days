import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty_juz_in_7_days/core/services/storage_service.dart';

void main() {
  test('Initial storage service setup returns expected defaults', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);

    expect(storage.isReminderEnabled, true);
    expect(storage.reminderTime.hour, 19);
    expect(storage.reminderTime.minute, 0);
    expect(storage.hasCompletedOnboarding, false);
    expect(storage.getActiveChallengeJson(), isNull);
  });
}
