import '../../domain/entities/challenge.dart';

class ChallengeState {
  /// True only while the very first load (or a full reset such as starting a
  /// new khatmah) is in progress.
  final bool isLoading;

  /// True once the initial load has finished at least once. Background
  /// refreshes never tear down the UI after this.
  final bool isInitialized;
  final Challenge? challenge;

  /// Archived challenges, newest first.
  final List<Challenge> history;
  final bool hasCompletedOnboarding;
  final String? errorMessage;
  final bool showCelebration;

  /// Set when a new cycle was started automatically (continuous mode).
  final bool autoStartedNewCycle;

  /// Daily reading plan split: 5 (by prayer), 3, 2, or 0 when turned off.
  final int readingPlanParts;

  bool get isReadingPlanOn => readingPlanParts > 0;

  /// When a backup file was last saved (null if never).
  final DateTime? lastBackupAt;

  const ChallengeState({
    this.isLoading = false,
    this.isInitialized = false,
    this.challenge,
    this.history = const [],
    this.hasCompletedOnboarding = false,
    this.errorMessage,
    this.showCelebration = false,
    this.autoStartedNewCycle = false,
    this.readingPlanParts = 5,
    this.lastBackupAt,
  });

  /// Number of khatmahs fully completed (archived + active).
  int get completedKhatmahCount {
    final ids = <String>{};
    var count = 0;
    for (final c in [?challenge, ...history]) {
      if (ids.add(c.id) && c.isAllPortionsCompleted) count++;
    }
    return count;
  }

  ChallengeState copyWith({
    bool? isLoading,
    bool? isInitialized,
    Challenge? challenge,
    List<Challenge>? history,
    bool? hasCompletedOnboarding,
    String? errorMessage,
    bool? showCelebration,
    bool? autoStartedNewCycle,
    int? readingPlanParts,
    DateTime? lastBackupAt,
    bool clearChallenge = false,
  }) {
    return ChallengeState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      challenge: clearChallenge ? null : (challenge ?? this.challenge),
      history: history ?? this.history,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      errorMessage: errorMessage,
      showCelebration: showCelebration ?? this.showCelebration,
      autoStartedNewCycle: autoStartedNewCycle ?? false,
      readingPlanParts: readingPlanParts ?? this.readingPlanParts,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
    );
  }
}
