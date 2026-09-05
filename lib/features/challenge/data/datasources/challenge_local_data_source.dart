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
    await _storageService.saveActiveChallengeJson(rawJson);
  }

  @override
  Future<void> archiveCompletedChallenge(ChallengeModel challenge) async {
    final rawJson = jsonEncode(challenge.toJson());
    await _storageService.addCompletedToHistory(rawJson);
    await _storageService.clearActiveChallenge();
  }

  @override
  Future<void> clearActiveChallenge() async {
    await _storageService.clearActiveChallenge();
  }
}
