import '../../domain/entities/challenge.dart';

class ChallengeState {
  final bool isLoading;
  final Challenge? challenge;
  final bool hasCompletedOnboarding;
  final String? errorMessage;
  final bool showCelebration;

  const ChallengeState({
    this.isLoading = false,
    this.challenge,
    this.hasCompletedOnboarding = false,
    this.errorMessage,
    this.showCelebration = false,
  });

  ChallengeState copyWith({
    bool? isLoading,
    Challenge? challenge,
    bool? hasCompletedOnboarding,
    String? errorMessage,
    bool? showCelebration,
    bool clearChallenge = false,
  }) {
    return ChallengeState(
      isLoading: isLoading ?? this.isLoading,
      challenge: clearChallenge ? null : (challenge ?? this.challenge),
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      errorMessage: errorMessage,
      showCelebration: showCelebration ?? this.showCelebration,
    );
  }
}
