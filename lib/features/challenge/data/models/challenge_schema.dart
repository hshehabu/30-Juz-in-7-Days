/// Versioning for the persisted challenge JSON.
///
/// Every saved challenge carries `schemaVersion`. Reading always goes through
/// [upgrade], which applies each step in order, so data written by any older
/// build (or restored from an old backup file) is brought up to date in one
/// place. When the format changes: bump [current], add a step, add a test.
class ChallengeSchema {
  ChallengeSchema._();

  static const int current = 2;
  static const String versionKey = 'schemaVersion';

  static Map<String, dynamic> upgrade(Map<String, dynamic> json) {
    final out = Map<String, dynamic>.from(json);
    var version = out[versionKey] is int ? out[versionKey] as int : 1;

    // v1 -> v2: per-day reading plan (readParts / partsCount / partsCustom)
    // replaces the short-lived surah checklist (readSurahs).
    if (version < 2) {
      out['portions'] = [
        for (final p in (out['portions'] as List<dynamic>? ?? const []))
          if (p is Map)
            (Map<String, dynamic>.from(p)
              ..remove('readSurahs')
              ..putIfAbsent('readParts', () => <int>[])
              ..putIfAbsent('partsCount', () => 5)
              ..putIfAbsent('partsCustom', () => false)),
      ];
      version = 2;
    }

    // Data from a newer app version is read best-effort (unknown fields are
    // ignored) and keeps its version number.
    out[versionKey] = version;
    return out;
  }
}
