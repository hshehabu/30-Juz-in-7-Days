import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Robust local storage service featuring:
/// - In-memory caching for optimized, zero-latency reads
/// - Pre-write JSON validation to prevent storage corruption
/// - Rolling snapshots of the last good versions & self-healing recovery
/// - Defensively sanitizes historical lists against corrupted entries
class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const String _keyActiveChallenge = 'active_khatmah_challenge';
  static const String _keyActiveChallengeBackup = 'active_khatmah_challenge_backup';
  static const String _keyActiveChallengeSnapshots = 'active_khatmah_challenge_snapshots';
  static const String _keyCompletedHistory = 'completed_khatmah_history';
  static const String _keyCompletedHistoryBackup = 'completed_khatmah_history_backup';
  static const String _keyReminderEnabled = 'reminder_enabled';
  static const String _keyReminderHour = 'reminder_hour';
  static const String _keyReminderMinute = 'reminder_minute';
  static const String _keyHasCompletedOnboarding = 'has_completed_onboarding';
  static const String _keyFollowUpEnabled = 'follow_up_enabled';
  static const String _keyFollowUpHour = 'follow_up_hour';
  static const String _keyFollowUpMinute = 'follow_up_minute';
  static const String _keyLanguageCode = 'app_language_code';
  static const String _keyAutoContinue = 'auto_continue_khatmah';
  static const String _keyReadingPlanParts = 'reading_plan_parts';
  static const String _keyLastBackupAt = 'last_backup_at';
  // In-memory cache for fast, synchronous access
  String? _cachedActiveChallengeJson;
  List<String>? _cachedHistoryJsonList;

  /// Incremented whenever stored history may have changed, so callers can
  /// cache decoded history and only rebuild it when this value moves.
  int _historyRevision = 0;
  int get historyRevision => _historyRevision;

  // ───────────────────────────────────────────────────────────────────────────
  // VALIDATION & INTEGRITY HELPERS
  // ───────────────────────────────────────────────────────────────────────────

  /// Verifies that a JSON string represents a structurally sound challenge
  bool _isValidChallengeJson(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) return false;
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) return false;
      return decoded.containsKey('id') &&
          decoded.containsKey('startDate') &&
          decoded.containsKey('portions');
    } catch (_) {
      return false;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ACTIVE CHALLENGE (rolling snapshots & self-healing)
  // ───────────────────────────────────────────────────────────────────────────

  /// Number of previous good versions kept for recovery.
  static const int snapshotCount = 3;

  /// Previous good versions of the active challenge, newest first.
  List<String> _snapshots() =>
      _prefs.getStringList(_keyActiveChallengeSnapshots) ?? const [];

  /// Retrieves active challenge JSON with automatic corruption fallback:
  /// primary slot, then the newest valid snapshot, then the legacy backup.
  String? getActiveChallengeJson() {
    // 1. Check in-memory cache first
    if (_cachedActiveChallengeJson != null) {
      return _cachedActiveChallengeJson;
    }

    // 2. Read primary slot from SharedPreferences
    final primary = _prefs.getString(_keyActiveChallenge);
    if (_isValidChallengeJson(primary)) {
      _cachedActiveChallengeJson = primary;
      return primary;
    }

    // 3. Primary slot corrupted or missing: recover from the newest valid
    // snapshot (or the single backup slot written by older versions).
    final candidates = [
      ..._snapshots(),
      ?_prefs.getString(_keyActiveChallengeBackup),
    ];
    for (final candidate in candidates) {
      if (_isValidChallengeJson(candidate)) {
        // Self-heal: restore primary slot from the recovered copy
        _prefs.setString(_keyActiveChallenge, candidate);
        _cachedActiveChallengeJson = candidate;
        return candidate;
      }
    }

    _cachedActiveChallengeJson = null;
    return null;
  }

  /// Persists active challenge JSON with pre-write validation. The version
  /// being replaced is pushed onto the rolling snapshot list first.
  Future<bool> saveActiveChallengeJson(String json) async {
    if (!_isValidChallengeJson(json)) {
      // Reject malformed JSON to protect storage integrity
      return false;
    }

    try {
      final current = _prefs.getString(_keyActiveChallenge);
      if (current != json && _isValidChallengeJson(current)) {
        final snapshots = [
          current!,
          ..._snapshots().where((s) => s != current),
        ].take(snapshotCount).toList();
        await _prefs.setStringList(_keyActiveChallengeSnapshots, snapshots);
      }

      final success = await _prefs.setString(_keyActiveChallenge, json);
      if (success) {
        _cachedActiveChallengeJson = json;
        // Snapshots supersede the single legacy backup slot.
        if (_prefs.containsKey(_keyActiveChallengeBackup)) {
          await _prefs.remove(_keyActiveChallengeBackup);
        }
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  /// Clears the active challenge and its snapshots (e.g. after archiving it,
  /// so an archived khatmah can never be "recovered" as the active one).
  Future<bool> clearActiveChallenge() async {
    _cachedActiveChallengeJson = null;
    await _prefs.remove(_keyActiveChallengeBackup);
    await _prefs.remove(_keyActiveChallengeSnapshots);
    return _prefs.remove(_keyActiveChallenge);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // COMPLETED KHATMAHS HISTORY
  // ───────────────────────────────────────────────────────────────────────────

  /// Retrieves sanitized history list, filtering out any corrupt entries
  List<String> getHistoryJsonList() {
    if (_cachedHistoryJsonList != null) {
      return List<String>.unmodifiable(_cachedHistoryJsonList!);
    }

    var list = _prefs.getStringList(_keyCompletedHistory);
    // If primary history missing, check backup history
    if (list == null || list.isEmpty) {
      list = _prefs.getStringList(_keyCompletedHistoryBackup);
    }

    if (list == null) {
      _cachedHistoryJsonList = [];
      return [];
    }

    // Filter only valid entries
    final sanitized = list.where((item) => _isValidChallengeJson(item)).toList();
    _cachedHistoryJsonList = sanitized;
    return List<String>.unmodifiable(sanitized);
  }

  /// Adds a completed challenge to history with atomic backup
  Future<bool> addCompletedToHistory(String challengeJson) async {
    if (!_isValidChallengeJson(challengeJson)) return false;

    try {
      final currentList = getHistoryJsonList().toList();
      // Backup current history before modifying
      await _prefs.setStringList(_keyCompletedHistoryBackup, currentList);

      currentList.insert(0, challengeJson);
      final success = await _prefs.setStringList(_keyCompletedHistory, currentList);
      if (success) {
        _cachedHistoryJsonList = currentList;
        _historyRevision++;
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  /// Saves entire history list after validation
  Future<bool> saveHistoryJsonList(List<String> list) async {
    try {
      final sanitized = list.where((item) => _isValidChallengeJson(item)).toList();
      final currentList = getHistoryJsonList().toList();
      await _prefs.setStringList(_keyCompletedHistoryBackup, currentList);

      final success = await _prefs.setStringList(_keyCompletedHistory, sanitized);
      if (success) {
        _cachedHistoryJsonList = sanitized;
        _historyRevision++;
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearHistory() async {
    _cachedHistoryJsonList = [];
    _historyRevision++;
    await _prefs.remove(_keyCompletedHistoryBackup);
    return _prefs.remove(_keyCompletedHistory);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // REMINDERS & PREFERENCES
  // ───────────────────────────────────────────────────────────────────────────

  bool get isReminderEnabled => _prefs.getBool(_keyReminderEnabled) ?? true;

  Future<bool> setReminderEnabled(bool enabled) {
    return _prefs.setBool(_keyReminderEnabled, enabled);
  }

  TimeOfDay get reminderTime {
    final hour = _prefs.getInt(_keyReminderHour) ?? 19; // Default 7:00 PM
    final minute = _prefs.getInt(_keyReminderMinute) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<bool> setReminderTime(TimeOfDay time) async {
    await _prefs.setInt(_keyReminderHour, time.hour);
    return _prefs.setInt(_keyReminderMinute, time.minute);
  }

  /// Optional second "gentle nudge" if the day's portion is still unread.
  bool get isFollowUpEnabled => _prefs.getBool(_keyFollowUpEnabled) ?? false;

  Future<bool> setFollowUpEnabled(bool enabled) {
    return _prefs.setBool(_keyFollowUpEnabled, enabled);
  }

  TimeOfDay get followUpTime {
    final hour = _prefs.getInt(_keyFollowUpHour) ?? 22; // Default 10:00 PM
    final minute = _prefs.getInt(_keyFollowUpMinute) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<bool> setFollowUpTime(TimeOfDay time) async {
    await _prefs.setInt(_keyFollowUpHour, time.hour);
    return _prefs.setInt(_keyFollowUpMinute, time.minute);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // LANGUAGE & PREFERENCES
  // ───────────────────────────────────────────────────────────────────────────

  /// Language code ('en' / 'ar') used for notifications, which are built
  /// outside the widget tree (and in background isolates).
  String get languageCode => _prefs.getString(_keyLanguageCode) ?? 'en';

  Future<bool> setLanguageCode(String code) {
    return _prefs.setString(_keyLanguageCode, code);
  }

  /// How each day is split for tracking: 5 (one part per prayer, default),
  /// 3 or 2 equal sittings, or 0 when the reading plan is turned off.
  int get readingPlanParts {
    final value = _prefs.getInt(_keyReadingPlanParts) ?? 5;
    return const [0, 2, 3, 5].contains(value) ? value : 5;
  }

  Future<bool> setReadingPlanParts(int parts) {
    return _prefs.setInt(_keyReadingPlanParts, parts);
  }

  /// Automatically begin the next 7-day khatmah once one is completed.
  bool get isAutoContinueEnabled =>
      _prefs.getBool(_keyAutoContinue) ?? false;

  Future<bool> setAutoContinueEnabled(bool enabled) {
    return _prefs.setBool(_keyAutoContinue, enabled);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ONBOARDING
  // ───────────────────────────────────────────────────────────────────────────

  bool get hasCompletedOnboarding =>
      _prefs.getBool(_keyHasCompletedOnboarding) ?? false;

  Future<bool> setOnboardingCompleted(bool completed) {
    return _prefs.setBool(_keyHasCompletedOnboarding, completed);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CROSS-ISOLATE SYNC
  // ───────────────────────────────────────────────────────────────────────────

  /// Re-reads values from disk and drops in-memory caches. Needed after a
  /// notification action wrote progress from a background isolate.
  Future<void> reloadFromDisk() async {
    try {
      await _prefs.reload();
    } catch (_) {}
    _cachedActiveChallengeJson = null;
    _cachedHistoryJsonList = null;
    _historyRevision++;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BACKUP EXPORT / IMPORT
  // ───────────────────────────────────────────────────────────────────────────

  static const int backupFormatVersion = 1;
  static const String backupMarker = 'thirty_juz_backup';

  /// When the user last saved a backup file (null if never).
  DateTime? get lastBackupAt {
    final raw = _prefs.getString(_keyLastBackupAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<bool> setLastBackupAt(DateTime time) {
    return _prefs.setString(_keyLastBackupAt, time.toIso8601String());
  }
  /// Serializes all progress and preferences into a portable JSON string.
  String exportBackup() {
    final active = getActiveChallengeJson();
    return jsonEncode({
      'format': backupMarker,
      'version': backupFormatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'active': active != null ? jsonDecode(active) : null,
      'history': getHistoryJsonList().map(jsonDecode).toList(),
      'settings': {
        'reminderEnabled': isReminderEnabled,
        'reminderHour': reminderTime.hour,
        'reminderMinute': reminderTime.minute,
        'followUpEnabled': isFollowUpEnabled,
        'followUpHour': followUpTime.hour,
        'followUpMinute': followUpTime.minute,
        'autoContinue': isAutoContinueEnabled,
        'readingPlanParts': readingPlanParts,
      },
    });
  }

  /// Restores a backup produced by [exportBackup]. Returns false (and leaves
  /// existing data untouched) when the payload is not a valid backup.
  Future<bool> importBackup(String raw) async {
    try {
      final decoded = jsonDecode(raw.trim());
      if (decoded is! Map<String, dynamic> ||
          decoded['format'] != backupMarker) {
        return false;
      }

      final active = decoded['active'];
      final activeJson = active == null ? null : jsonEncode(active);
      if (activeJson != null && !_isValidChallengeJson(activeJson)) {
        return false;
      }

      final history = (decoded['history'] as List<dynamic>? ?? [])
          .map((e) => jsonEncode(e))
          .where(_isValidChallengeJson)
          .toList();

      if (activeJson != null) {
        await saveActiveChallengeJson(activeJson);
        await setOnboardingCompleted(true);
      } else {
        await clearActiveChallenge();
      }
      await saveHistoryJsonList(history);

      final settings = decoded['settings'];
      if (settings is Map<String, dynamic>) {
        if (settings['reminderEnabled'] is bool) {
          await setReminderEnabled(settings['reminderEnabled'] as bool);
        }
        if (settings['reminderHour'] is int && settings['reminderMinute'] is int) {
          await setReminderTime(TimeOfDay(
            hour: settings['reminderHour'] as int,
            minute: settings['reminderMinute'] as int,
          ));
        }
        if (settings['followUpEnabled'] is bool) {
          await setFollowUpEnabled(settings['followUpEnabled'] as bool);
        }
        if (settings['followUpHour'] is int && settings['followUpMinute'] is int) {
          await setFollowUpTime(TimeOfDay(
            hour: settings['followUpHour'] as int,
            minute: settings['followUpMinute'] as int,
          ));
        }
        if (settings['autoContinue'] is bool) {
          await setAutoContinueEnabled(settings['autoContinue'] as bool);
        }
        if (settings['readingPlanParts'] is int) {
          await setReadingPlanParts(settings['readingPlanParts'] as int);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
