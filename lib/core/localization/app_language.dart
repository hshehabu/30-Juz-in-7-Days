import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Central language and localization coordinator.
///:
/// - Maintains supported languages
/// - Ready for adding future languages (e.g. Urdu, French, Indonesian)
/// - Provides easy locale switching and helper queries
abstract class AppLanguage {
  /// All supported locales in the application.
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  /// Fallback locale when device locale is not supported.
  static const Locale fallbackLocale = Locale('en');

  /// Human-readable native names for each supported language.
  static const Map<String, String> languageNames = {
    'en': 'English',
    'ar': 'العربية',
  };

  /// Returns whether the current active locale in [context] is Arabic.
  static bool isArabic(BuildContext context) {
    return context.locale.languageCode == 'ar';
  }

  /// Puts the app in [locale].
  static Future<void> switchLanguage(BuildContext context, Locale locale) async {
    if (context.locale.languageCode == locale.languageCode) return;
    Intl.defaultLocale = locale.languageCode;
    await context.setLocale(locale);
  }
}
