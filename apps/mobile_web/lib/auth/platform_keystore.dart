/// Refresh-token storage. iOS Keychain and Android Keystore are not wired.
/// Device persistence is untested. Web must not use browser storage.
abstract class PlatformKeystore {
  Future<void> writeRefreshToken(String token);
  Future<String?> readRefreshToken();
  Future<void> clearRefreshToken();
}

/// In-memory stand-in for tests. It does not survive a process restart.
class MemoryPlatformKeystore implements PlatformKeystore {
  String? _token;

  @override
  Future<void> clearRefreshToken() async {
    _token = null;
  }

  @override
  Future<String?> readRefreshToken() async => _token;

  @override
  Future<void> writeRefreshToken(String token) async {
    _token = token;
  }
}

/// Used for iOS and Android in this build. The keystore plugin is not configured.
class UnconfiguredPlatformKeystore implements PlatformKeystore {
  @override
  Future<void> clearRefreshToken() async {}

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> writeRefreshToken(String token) async {
    throw StateError(
      'The iOS Keychain and Android Keystore plugin is not configured. Device persistence is untested.',
    );
  }
}

/// Web stays in local mode. This store does not touch browser storage.
class WebLocalModeTokenStore implements PlatformKeystore {
  @override
  Future<void> clearRefreshToken() async {}

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> writeRefreshToken(String token) async {
    throw StateError(
      'Web stays in local mode and does not store a refresh token.',
    );
  }
}

PlatformKeystore keystoreFor({required bool web}) {
  if (web) return WebLocalModeTokenStore();
  return UnconfiguredPlatformKeystore();
}
