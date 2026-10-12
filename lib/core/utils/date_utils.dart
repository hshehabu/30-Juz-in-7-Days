import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static String _resolveLocale(String? locale) {
    if (locale != null && locale.isNotEmpty) {
      return locale.startsWith('ar') ? 'ar' : locale;
    }
    final def = Intl.defaultLocale;
    if (def != null && def.isNotEmpty) {
      return def.startsWith('ar') ? 'ar' : def;
    }
    return 'en';
  }

  static String formatDate(DateTime date, [String? locale]) {
    final loc = _resolveLocale(locale);
    if (loc == 'ar') {
      return DateFormat('d MMMM', 'ar').format(date);
    }
    return DateFormat('MMMM d', loc).format(date);
  }

  static String formatDateWithYear(DateTime date, [String? locale]) {
    final loc = _resolveLocale(locale);
    if (loc == 'ar') {
      return DateFormat('d MMMM yyyy', 'ar').format(date);
    }
    return DateFormat('MMMM d, yyyy', loc).format(date);
  }

  static String formatShortDate(DateTime date, [String? locale]) {
    final loc = _resolveLocale(locale);
    if (loc == 'ar') {
      return DateFormat('d MMM', 'ar').format(date);
    }
    return DateFormat('MMM d', loc).format(date);
  }

  static String formatWeekday(DateTime date, [String? locale]) {
    final loc = _resolveLocale(locale);
    return DateFormat('EEE', loc).format(date);
  }

  static String formatDayOfMonth(DateTime date, [String? locale]) {
    final loc = _resolveLocale(locale);
    return DateFormat('d', loc).format(date);
  }

  static String formatMonthYear(DateTime date, [String? locale]) {
    final loc = _resolveLocale(locale);
    return DateFormat('MMMM yyyy', loc).format(date);
  }

  static String formatTimeOfDay(TimeOfDay time, [String? locale]) {
    final loc = _resolveLocale(locale);
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a', loc).format(dt);
  }

  /// Normalizes a DateTime to start of day (midnight)
  static DateTime dateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// Calculates which day of the challenge today is (1-indexed).
  /// If today is before startDate, returns 0.
  /// If today is startDate, returns 1.
  /// If 6 days after, returns 7.
  /// If beyond 7 days, returns > 7.
  static int calculateCurrentDayNumber(DateTime startDate, [DateTime? today]) {
    final start = dateOnly(startDate);
    final current = dateOnly(today ?? DateTime.now());
    final diffDays = current.difference(start).inDays;
    return diffDays + 1;
  }
}
