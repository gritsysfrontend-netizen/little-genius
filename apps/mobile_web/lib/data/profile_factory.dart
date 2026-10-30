import '../domain/ids.dart';
import '../domain/profile.dart';

ChildProfile profileFromDraft(ProfileDraft draft) {
  final nickname = normalizeNickname(draft.nickname);
  if (nickname == null ||
      !validAvatar(draft.avatarId) ||
      !validAgeBand(draft.ageBand) ||
      !validLocale(draft.preferredLocale)) {
    throw ArgumentError('profile');
  }
  return ChildProfile(
    profileId: uuidV4(),
    nickname: nickname,
    avatarId: draft.avatarId,
    ageBand: draft.ageBand,
    preferredLocale: draft.preferredLocale,
    bilingualMode: draft.bilingualMode,
    revision: 1,
  );
}
