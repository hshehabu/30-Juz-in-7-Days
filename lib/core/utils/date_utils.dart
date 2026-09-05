import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static String formatDate(DateTime date) {
    return DateFormat('MMMM d').format(date);
  }

  static String formatDateWithYear(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  static String formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
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
