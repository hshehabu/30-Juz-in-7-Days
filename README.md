# 30 Juz' in 7 Days

An offline, bilingual (English / Arabic) Flutter app that helps you complete the
Qur'an in seven days using the traditional 3 / 5 / 7 / 9 / 11 / 13 / Mufassal
division (Sahih al-Bukhari 5054). It is a pacing, tracking and reminder
companion, not a Qur'an reader.

- Daily portion with page range (604-page Madani mushaf) and realistic reading time
- A reading plan that splits each day into parts (by prayer, 3 or 2 sittings,
  or off); tick a part when you finish it and the app remembers where you stopped
- Daily reminder plus an optional follow-up nudge, in the app's language
- Journey view with cycle history and lifetime stats
- Plan adjustment when you fall behind, late check-in for missed days
- Optional continuous mode, copy/paste backup and restore
- Android home-screen widget with a "Mark done" button; share a completed khatmah
- No account, no network access, all data stays on the device

See [docs/FEATURE_REPORT.md](docs/FEATURE_REPORT.md) for the full feature list.

## Development

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Architecture: feature-first folders under `lib/features/` with
domain / data / presentation layers, Riverpod (`StateNotifier`) for state,
SharedPreferences (primary + backup slot) for storage, and
`flutter_local_notifications` for reminders. Reminder timing rules live in
`lib/core/services/reminder_planner.dart`, a pure function shared by the
scheduler and the Settings countdown.

Translations are in `assets/translations/{en,ar}.json`. After adding keys,
update `lib/core/localization/locale_keys.g.dart` to match (both files must
keep the same keys; `test/localization_coverage_test.dart` checks this).

## Release signing (Android)

Release builds read signing details from `android/key.properties`, which is
gitignored. Without it, release builds fall back to the debug key and Gradle
prints a warning. **Debug-signed APKs cannot be updated by a build signed on
another machine**, so set this up before distributing.

1. Create a keystore once and back it up somewhere safe (losing it means users
   can never receive updates):

   ```bash
   keytool -genkey -v -keystore ~/thirtyjuz-release.jks -keyalg RSA \
     -keysize 2048 -validity 10000 -alias thirtyjuz
   ```

2. Create `android/key.properties`:

   ```properties
   storeFile=C:/Users/<you>/thirtyjuz-release.jks
   storePassword=<store password>
   keyAlias=thirtyjuz
   keyPassword=<key password>
   ```

3. Build:

   ```bash
   flutter build apk --release
   # or, for the Play Store
   flutter build appbundle --release
   ```

Application ID: `com.hshehabu.thirtyjuz`.
