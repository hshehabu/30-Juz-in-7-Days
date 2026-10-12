import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncMemoryAssetLoader extends AssetLoader {
  static final Map<String, Map<String, dynamic>> _cachedTranslations = {
    'en': json.decode(File('assets/translations/en.json').readAsStringSync())
        as Map<String, dynamic>,
    'ar': json.decode(File('assets/translations/ar.json').readAsStringSync())
        as Map<String, dynamic>,
  };

  const SyncMemoryAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) {
    return Future.value(_cachedTranslations[locale.languageCode] ?? {});
  }
}

Future<void> initTestLocalization() async {
  SharedPreferences.setMockInitialValues({});
  EasyLocalization.logger.enableLevels = [];
  await EasyLocalization.ensureInitialized();
}

Widget wrapWithLocalization(
  Widget child, {
  Locale locale = const Locale('en'),
}) {
  return EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('ar')],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    startLocale: locale,
    useOnlyLangCode: true,
    assetLoader: const SyncMemoryAssetLoader(),
    child: Builder(
      builder: (context) => MaterialApp(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: Scaffold(body: child),
      ),
    ),
  );
}
