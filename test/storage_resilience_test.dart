import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thirty_juz_in_7_days/core/constants/khatmah_constants.dart';
import 'package:thirty_juz_in_7_days/core/services/notification_service.dart';
import 'package:thirty_juz_in_7_days/core/services/storage_service.dart';
import 'package:thirty_juz_in_7_days/features/backup/backup_actions.dart';
import 'package:thirty_juz_in_7_days/features/challenge/data/datasources/challenge_local_data_source.dart';
import 'package:thirty_juz_in_7_days/features/challenge/data/models/challenge_model.dart';
import 'package:thirty_juz_in_7_days/features/challenge/data/models/challenge_schema.dart';
import 'package:thirty_juz_in_7_days/features/challenge/data/repositories/challenge_repository_impl.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/challenge.dart';
import 'package:thirty_juz_in_7_days/features/challenge/domain/entities/day_portion.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/notifiers/challenge_notifier.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/notifiers/challenge_providers.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/notifiers/challenge_state.dart';
import 'package:thirty_juz_in_7_days/features/challenge/presentation/pages/home_page.dart';
import 'test_helper.dart';

String _challengeJson(String id, {int completedDays = 0}) => jsonEncode({
      'id': id,
      'startDate': '2026-11-10T00:00:00.000',
      'endDate': '2026-11-16T00:00:00.000',
      'createdAt': '2026-11-10T00:00:00.000',
      'portions': [
        for (final d in KhatmahConstants.traditionalSchedule)
          {
            'dayNumber': d.dayNumber,
            'startSurah': d.startSurah,
            'endSurah': d.endSurah,
            'surahCount': d.surahCount,
            'isCompleted': d.dayNumber <= completedDays,
          },
      ],
    });

Future<(StorageService, SharedPreferences)> _storage(
    [Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  return (StorageService(prefs), prefs);
}

class _SilentNotifications extends NotificationService {
  @override
  Future<void> scheduleChallengeReminders({
    required DateTime startDate,
    TimeOfDay reminderTime = const TimeOfDay(hour: 19, minute: 0),
    required List<DefaultPortionData> schedule,
    Set<int> completedDays = const {},
    TimeOfDay? followUpTime,
    String? languageCode,
  }) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelDayReminder(int dayNumber) async {}

  @override
  Future<void> showCompletionNotification() async {}
}

class _FakeNotifier extends StateNotifier<ChallengeState>
    implements ChallengeNotifier {
  _FakeNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initTestLocalization();
  });

  group('Rolling snapshots', () {
    test('keeps the last three previous versions, newest first', () async {
      final (storage, prefs) = await _storage();
      for (var i = 1; i <= 5; i++) {
        await storage.saveActiveChallengeJson(_challengeJson('v$i'));
      }
      final snapshots = prefs
          .getStringList('active_khatmah_challenge_snapshots')!
          .map((s) => (jsonDecode(s) as Map)['id'])
          .toList();
      expect(snapshots, ['v4', 'v3', 'v2']);
    });

    test('recovers the newest valid snapshot when the primary is corrupted',
        () async {
      final (_, prefs) = await _storage();
      await prefs.setString('active_khatmah_challenge', '{broken');
      await prefs.setStringList('active_khatmah_challenge_snapshots', [
        'also broken',
        _challengeJson('good'),
      ]);
      final fresh = StorageService(prefs);
      final recovered = fresh.getActiveChallengeJson();
      expect((jsonDecode(recovered!) as Map)['id'], 'good');
      // Self-healed back into the primary slot.
      expect(prefs.getString('active_khatmah_challenge'), recovered);
    });

    test('still recovers from the legacy single backup slot, then retires it',
        () async {
      final (storage, prefs) = await _storage({
        'active_khatmah_challenge': 'corrupt',
        'active_khatmah_challenge_backup': _challengeJson('legacy'),
      });
      expect((jsonDecode(storage.getActiveChallengeJson()!) as Map)['id'],
          'legacy');
      await storage.saveActiveChallengeJson(_challengeJson('next'));
      expect(prefs.containsKey('active_khatmah_challenge_backup'), isFalse);
    });

    test('clearing the active challenge also clears its snapshots', () async {
      final (storage, prefs) = await _storage();
      await storage.saveActiveChallengeJson(_challengeJson('a'));
      await storage.saveActiveChallengeJson(_challengeJson('b'));
      await storage.clearActiveChallenge();
      expect(prefs.containsKey('active_khatmah_challenge_snapshots'), isFalse);
      expect(StorageService(prefs).getActiveChallengeJson(), isNull);
    });
  });

  group('Schema versioning', () {
    test('old data without a version is upgraded on read', () {
      final legacy = jsonDecode(_challengeJson('old')) as Map<String, dynamic>;
      (legacy['portions'] as List).first['readSurahs'] = [2, 3];
      final upgraded = ChallengeSchema.upgrade(legacy);
      expect(upgraded['schemaVersion'], ChallengeSchema.current);
      final day1 = (upgraded['portions'] as List).first as Map;
      expect(day1.containsKey('readSurahs'), isFalse);
      expect(day1['partsCount'], 5);

      final model = ChallengeModel.fromJson(legacy);
      expect(model.portions.first.readParts, isEmpty);
    });

    test('saved data is stamped with the current version', () {
      final model = ChallengeModel.fromJson(
          jsonDecode(_challengeJson('x')) as Map<String, dynamic>);
      expect(model.toJson()['schemaVersion'], ChallengeSchema.current);
    });

    test('data from a newer app version keeps its version number', () {
      final future = jsonDecode(_challengeJson('f')) as Map<String, dynamic>
        ..['schemaVersion'] = 99;
      expect(ChallengeSchema.upgrade(future)['schemaVersion'], 99);
    });
  });

  group('History caching', () {
    test('decoded history is reused until storage changes', () async {
      final (storage, _) = await _storage();
      final repo = ChallengeRepositoryImpl(
        localDataSource: ChallengeLocalDataSourceImpl(storage),
        notificationService: _SilentNotifications(),
        storageService: storage,
      );
      await storage.addCompletedToHistory(_challengeJson('h1', completedDays: 7));

      final first = await repo.getHistory();
      final second = await repo.getHistory();
      expect(identical(first, second), isTrue);

      await storage.addCompletedToHistory(_challengeJson('h2', completedDays: 7));
      final third = await repo.getHistory();
      expect(third.map((c) => c.id), ['h2', 'h1']);
    });
  });

  group('Backups', () {
    test('backup file name is dated', () {
      expect(BackupActions.fileName(DateTime(2026, 3, 7)),
          'thirty-juz-backup-2026-03-07.json');
    });

    test('Android backup rules include only the app settings file', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest, contains('android:dataExtractionRules="@xml/data_extraction_rules"'));
      expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
      for (final path in [
        'android/app/src/main/res/xml/data_extraction_rules.xml',
        'android/app/src/main/res/xml/backup_rules.xml',
      ]) {
        final xml = File(path).readAsStringSync();
        expect(xml, contains('path="FlutterSharedPreferences.xml"'));
        expect(RegExp('<include').allMatches(xml).length,
            path.contains('extraction') ? 2 : 1);
      }
    });

    Challenge finished() {
      final start = DateTime.now().subtract(const Duration(days: 2));
      return Challenge(
        id: 'done',
        startDate: start,
        endDate: start.add(const Duration(days: 6)),
        portions: KhatmahConstants.traditionalSchedule
            .map((d) => DayPortion(
                  dayNumber: d.dayNumber,
                  startSurah: d.startSurah,
                  endSurah: d.endSurah,
                  startSurahAr: d.startSurahAr,
                  endSurahAr: d.endSurahAr,
                  surahCount: d.surahCount,
                  isCompleted: true,
                  completedAt: start.add(const Duration(hours: 20)),
                ))
            .toList(),
        reminderHour: 19,
        reminderMinute: 0,
        createdAt: start,
      );
    }

    Future<void> pumpHome(WidgetTester tester, ChallengeState state) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(wrapWithLocalization(ProviderScope(
        overrides: [
          challengeStateProvider.overrideWith((ref) => _FakeNotifier(state)),
        ],
        child: HomePage(onNavigateToProgress: () {}, onStartNewKhatmah: () {}),
      )));
      await tester.pumpAndSettle();
    }

    testWidgets('completed khatmah prompts to save a backup', (tester) async {
      await pumpHome(
          tester, ChallengeState(isInitialized: true, challenge: finished()));
      expect(find.byKey(const Key('home_backup_prompt')), findsOneWidget);
    });

    testWidgets('no prompt once a backup was saved after finishing',
        (tester) async {
      await pumpHome(
        tester,
        ChallengeState(
          isInitialized: true,
          challenge: finished(),
          lastBackupAt: DateTime.now(),
        ),
      );
      expect(find.byKey(const Key('home_backup_prompt')), findsNothing);
    });
  });
}
