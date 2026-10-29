import '../domain/profile.dart';
import '../domain/progress_rules.dart';
import 'records.dart';

abstract class LearningRepository {
  Future<ChildProfile> createProfile(ProfileDraft draft);
  Future<ChildProfile?> getProfile(String profileId);
  Future<List<ChildProfile>> listProfiles();
  Future<ChildProfile> updateProfile(ChildProfile profile);
  Future<void> setActiveProfileId(String profileId);
  Future<String?> getActiveProfileId();
  Future<void> setSetting(String key, String value);
  Future<String?> getSetting(String key);

  Future<void> saveDocument(StoredDocument document);
  Future<StoredDocument?> getDocument(String contentId, int contentVersion);
  Future<StoredDocument?> latestDocument(String contentId);
  Future<List<StoredDocument>> listDocuments();

  Future<void> saveBlob(StoredBlob blob);
  Future<StoredBlob?> getBlob(String assetId);
  Future<void> deleteBlob(String assetId);
  Future<int> storageUsedBytes();

  Future<ApplyResult> applyEvent({
    required String profileId,
    required String categoryId,
    required LearningEvent event,
  });
  Future<List<LearningEvent>> listEvents(String profileId);
  Future<List<ProgressSummary>> listProgress(String profileId);
  Future<List<OutboxEntry>> listOutbox(String profileId);

  Future<void> close();
}
