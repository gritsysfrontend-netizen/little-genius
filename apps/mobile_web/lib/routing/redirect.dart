String? redirectFor({
  required String location,
  required bool sessionLoading,
  required bool hasProfile,
  required bool gateUnlocked,
}) {
  if (sessionLoading) return location == '/loading' ? null : '/loading';
  final onboarding =
      location == '/welcome' ||
      location == '/language' ||
      location == '/local' ||
      location == '/profile';
  final parent = location.startsWith('/parent');
  if (!hasProfile && !onboarding) return '/welcome';
  if (hasProfile && onboarding) return '/';
  if (parent && location != '/parent/gate' && !gateUnlocked) {
    return '/parent/gate';
  }
  if (location == '/parent/gate' && gateUnlocked) return '/parent';
  if (location == '/loading') return hasProfile ? '/' : '/welcome';
  return null;
}
