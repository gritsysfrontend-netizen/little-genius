import 'package:characters/characters.dart';

const avatarIds = ['star', 'sun', 'leaf', 'moon', 'bird', 'fish'];
const locales = ['en', 'hi', 'ta'];

class ChildProfile {
  const ChildProfile({
    required this.profileId,
    required this.nickname,
    required this.avatarId,
    required this.ageBand,
    required this.preferredLocale,
    required this.bilingualMode,
    required this.revision,
  });

  final String profileId;
  final String nickname;
  final String avatarId;
  final String ageBand;
  final String preferredLocale;
  final bool bilingualMode;
  final int revision;

  ChildProfile copyWith({
    String? nickname,
    String? avatarId,
    String? ageBand,
    String? preferredLocale,
    bool? bilingualMode,
    int? revision,
  }) {
    return ChildProfile(
      profileId: profileId,
      nickname: nickname ?? this.nickname,
      avatarId: avatarId ?? this.avatarId,
      ageBand: ageBand ?? this.ageBand,
      preferredLocale: preferredLocale ?? this.preferredLocale,
      bilingualMode: bilingualMode ?? this.bilingualMode,
      revision: revision ?? this.revision,
    );
  }
}

class ProfileDraft {
  const ProfileDraft({
    required this.nickname,
    required this.avatarId,
    required this.ageBand,
    required this.preferredLocale,
    required this.bilingualMode,
  });

  final String nickname;
  final String avatarId;
  final String ageBand;
  final String preferredLocale;
  final bool bilingualMode;
}

String? normalizeNickname(String raw) {
  final stripped = raw.replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), '').trim();
  final length = stripped.characters.length;
  if (length < 1 || length > 24) return null;
  return stripped;
}

bool validAvatar(String id) => avatarIds.contains(id);
bool validLocale(String id) => locales.contains(id);
bool validAgeBand(String id) =>
    id == '1-2' || id == '2-3' || id == '3-4' || id == '4-5';
