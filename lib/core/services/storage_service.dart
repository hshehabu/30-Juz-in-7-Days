import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const String _keyActiveChallenge = 'active_khatmah_challenge';
  static const String _keyCompletedHistory = 'completed_khatmah_history';
  static const String _keyReminderEnabled = 'reminder_enabled';
  static const String _keyReminderHour = 'reminder_hour';
  static const String _keyReminderMinute = 'reminder_minute';
  static const String _keyHasCompletedOnboarding = 'has_completed_onboarding';

  // --- Active Challenge ---
  String? getActiveChallengeJson() {
    return _prefs.getString(_keyActiveChallenge);
  }

  Future<bool> saveActiveChallengeJson(String json) {
    return _prefs.setString(_keyActiveChallenge, json);
  }

  Future<bool> clearActiveChallenge() {
    return _prefs.remove(_keyActiveChallenge);
  }

  // --- Completed Khatmahs History ---
  List<String> getHistoryJsonList() {
    return _prefs.getStringList(_keyCompletedHistory) ?? [];
  }

  Future<bool> addCompletedToHistory(String challengeJson) {
    final list = getHistoryJsonList().toList();
    list.insert(0, challengeJson);
    return _prefs.setStringList(_keyCompletedHistory, list);
  }

  // --- Reminders ---
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

  // --- Onboarding ---
  bool get hasCompletedOnboarding =>
      _prefs.getBool(_keyHasCompletedOnboarding) ?? false;

  Future<bool> setOnboardingCompleted(bool completed) {
    return _prefs.setBool(_keyHasCompletedOnboarding, completed);
  }
}
