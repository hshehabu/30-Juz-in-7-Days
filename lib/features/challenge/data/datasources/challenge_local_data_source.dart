import 'dart:convert';
import '../../../../core/services/storage_service.dart';
import '../models/challenge_model.dart';

abstract class ChallengeLocalDataSource {
  Future<ChallengeModel?> getActiveChallenge();
  Future<void> saveActiveChallenge(ChallengeModel challenge);
  Future<void> archiveCompletedChallenge(ChallengeModel challenge);
  Future<void> clearActiveChallenge();
}

class ChallengeLocalDataSourceImpl implements ChallengeLocalDataSource {
  final StorageService _storageService;

  ChallengeLocalDataSourceImpl(this._storageService);

  @override
  Future<ChallengeModel?> getActiveChallenge() async {
    final rawJson = _storageService.getActiveChallengeJson();
    if (rawJson == null || rawJson.isEmpty) return null;
    try {
      final Map<String, dynamic> map = jsonDecode(rawJson) as Map<String, dynamic>;
      return ChallengeModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveActiveChallenge(ChallengeModel challenge) async {
    final rawJson = jsonEncode(challenge.toJson());
    final saved = await _storageService.saveActiveChallengeJson(rawJson);
    if (!saved) {
      throw const StorageWriteException();
    }
  }

  @override
  Future<void> archiveCompletedChallenge(ChallengeModel challenge) async {
    final rawJson = jsonEncode(challenge.toJson());
    final archived = await _storageService.addCompletedToHistory(rawJson);
    if (!archived) {
      throw const StorageWriteException();
    }
    await _storageService.clearActiveChallenge();
  }

  @override
  Future<void> clearActiveChallenge() async {
    await _storageService.clearActiveChallenge();
  }
}

/// Thrown when progress could not be persisted to local storage.
class StorageWriteException implements Exception {
  const StorageWriteException();

  @override
  String toString() => 'StorageWriteException: progress could not be saved';
}
