import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Robust local storage service featuring:
/// - In-memory caching for optimized, zero-latency reads
/// - Pre-write JSON validation to prevent storage corruption
/// - Automatic dual-slot backup & self-healing recovery
/// - Defensively sanitizes historical lists against corrupted entries
class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const String _keyActiveChallenge = 'active_khatmah_challenge';
  static const String _keyActiveChallengeBackup = 'active_khatmah_challenge_backup';
  static const String _keyCompletedHistory = 'completed_khatmah_history';
  static const String _keyCompletedHistoryBackup = 'completed_khatmah_history_backup';
  static const String _keyReminderEnabled = 'reminder_enabled';
  static const String _keyReminderHour = 'reminder_hour';
  static const String _keyReminderMinute = 'reminder_minute';
  static const String _keyHasCompletedOnboarding = 'has_completed_onboarding';

  // In-memory cache for fast, synchronous access
  String? _cachedActiveChallengeJson;
  List<String>? _cachedHistoryJsonList;

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
  // ACTIVE CHALLENGE (Dual-slot backup & self-healing)
  // ───────────────────────────────────────────────────────────────────────────

  /// Retrieves active challenge JSON with automatic corruption fallback
  String? getActiveChallengeJson() {
    // 1. Check in-memory cache first
    if (_cachedActiveChallengeJson != null &&
        _isValidChallengeJson(_cachedActiveChallengeJson)) {
      return _cachedActiveChallengeJson;
    }

    // 2. Read primary slot from SharedPreferences
    final primary = _prefs.getString(_keyActiveChallenge);
    if (_isValidChallengeJson(primary)) {
      _cachedActiveChallengeJson = primary;
      return primary;
    }

    // 3. Primary slot corrupted or missing: attempt recovery from backup slot
    final backup = _prefs.getString(_keyActiveChallengeBackup);
    if (_isValidChallengeJson(backup)) {
      // Self-heal: restore primary slot from valid backup
      _prefs.setString(_keyActiveChallenge, backup!);
      _cachedActiveChallengeJson = backup;
      return backup;
    }

    _cachedActiveChallengeJson = null;
    return null;
  }

  /// Persists active challenge JSON with pre-write validation and backup preservation
  Future<bool> saveActiveChallengeJson(String json) async {
    if (!_isValidChallengeJson(json)) {
      // Reject malformed JSON to protect storage integrity
      return false;
    }

    try {
      // Preserve existing valid primary state into backup slot before overwriting
      final current = _prefs.getString(_keyActiveChallenge);
      if (_isValidChallengeJson(current)) {
        await _prefs.setString(_keyActiveChallengeBackup, current!);
      }

      final success = await _prefs.setString(_keyActiveChallenge, json);
      if (success) {
        _cachedActiveChallengeJson = json;
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  /// Clears active challenge and its backup slot
  Future<bool> clearActiveChallenge() async {
    _cachedActiveChallengeJson = null;
    await _prefs.remove(_keyActiveChallengeBackup);
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
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearHistory() async {
    _cachedHistoryJsonList = [];
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

  // ───────────────────────────────────────────────────────────────────────────
  // ONBOARDING
  // ───────────────────────────────────────────────────────────────────────────

  bool get hasCompletedOnboarding =>
      _prefs.getBool(_keyHasCompletedOnboarding) ?? false;

  Future<bool> setOnboardingCompleted(bool completed) {
    return _prefs.setBool(_keyHasCompletedOnboarding, completed);
  }
}
