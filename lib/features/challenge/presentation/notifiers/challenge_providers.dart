import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/datasources/challenge_local_data_source.dart';
import '../../data/repositories/challenge_repository_impl.dart';
import '../../domain/repositories/challenge_repository.dart';
import 'challenge_notifier.dart';
import 'challenge_state.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageServiceProvider must be overridden in main');
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final challengeLocalDataSourceProvider =
    Provider<ChallengeLocalDataSource>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ChallengeLocalDataSourceImpl(storage);
});

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  final localDataSource = ref.watch(challengeLocalDataSourceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final storageService = ref.watch(storageServiceProvider);

  return ChallengeRepositoryImpl(
    localDataSource: localDataSource,
    notificationService: notificationService,
    storageService: storageService,
  );
});

final challengeStateProvider =
    StateNotifierProvider<ChallengeNotifier, ChallengeState>((ref) {
  final repository = ref.watch(challengeRepositoryProvider);
  final storageService = ref.watch(storageServiceProvider);

  return ChallengeNotifier(
    repository: repository,
    storageService: storageService,
  );
});
