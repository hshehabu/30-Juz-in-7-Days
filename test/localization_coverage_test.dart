import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

bool _hasArabic(String value) {
  return value.runes.any((r) => r >= 0x0600 && r <= 0x06FF);
}

Map<String, String> _flatten(Map<String, dynamic> node, [String prefix = '']) {
  final out = <String, String>{};
  node.forEach((key, value) {
    final path = prefix.isEmpty ? key : '$prefix.$key';
    if (value is Map<String, dynamic>) {
      out.addAll(_flatten(value, path));
    } else if (value is String) {
      out[path] = value;
    }
  });
  return out;
}

Map<String, String> _load(String locale) => _flatten(
      json.decode(File('assets/translations/$locale.json').readAsStringSync())
          as Map<String, dynamic>,
    );

void main() {
  group('Localization Coverage & Key Parity', () {
    late Map<String, String> en;
    late Map<String, String> ar;

    setUpAll(() {
      en = _load('en');
      ar = _load('ar');
    });

    test('en.json and ar.json are both non-empty', () {
      expect(en, isNotEmpty);
      expect(ar, isNotEmpty);
    });

    test('Every key in en.json exists in ar.json', () {
      final missingInAr = <String>[];
      for (final key in en.keys) {
        if (!ar.containsKey(key)) {
          missingInAr.add(key);
        }
      }
      expect(
        missingInAr,
        isEmpty,
        reason: 'Keys present in en.json but missing in ar.json: $missingInAr',
      );
    });

    test('Every key in ar.json exists in en.json', () {
      final missingInEn = <String>[];
      for (final key in ar.keys) {
        if (!en.containsKey(key)) {
          missingInEn.add(key);
        }
      }
      expect(
        missingInEn,
        isEmpty,
        reason: 'Keys present in ar.json but missing in en.json: $missingInEn',
      );
    });

    test('Every Arabic translation contains authentic Arabic characters', () {
      final nonArabicValues = <String, String>{};
      for (final entry in ar.entries) {
        // Skip keys that are intentionally numerical or symbolic (e.g. version)
        if (entry.key.contains('version')) continue;
        if (!_hasArabic(entry.value)) {
          nonArabicValues[entry.key] = entry.value;
        }
      }
      expect(
        nonArabicValues,
        isEmpty,
        reason: 'Values in ar.json missing Arabic characters: $nonArabicValues',
      );
    });

    test('Interpolation placeholders match between English and Arabic', () {
      final mismatched = <String>[];
      for (final key in en.keys) {
        if (!ar.containsKey(key)) continue;
        final enPlaceholders = '{}'.allMatches(en[key]!).length;
        final arPlaceholders = '{}'.allMatches(ar[key]!).length;
        if (enPlaceholders != arPlaceholders) {
          mismatched.add(
            '$key (EN: $enPlaceholders placeholders, AR: $arPlaceholders placeholders)',
          );
        }
      }
      expect(
        mismatched,
        isEmpty,
        reason: 'Placeholder count mismatch between en and ar: $mismatched',
      );
    });
  });
}
