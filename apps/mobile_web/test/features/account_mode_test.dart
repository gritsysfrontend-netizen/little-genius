import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_genius/auth/pkce.dart';
import 'package:little_genius/auth/platform_keystore.dart';
import 'package:little_genius/data/memory/memory_repository.dart';
import 'package:little_genius/domain/profile.dart';
import 'package:little_genius/domain/progress_rules.dart';
import 'package:little_genius/features/parent/account_conversion.dart';
import 'package:little_genius/features/parent/account_screen.dart';
import 'package:little_genius/l10n/app_localizations.dart';
import 'package:little_genius/routing/providers.dart';
import 'package:little_genius/theme/app_theme.dart';

void main() {
  test('PKCE uses S256 and does not add a client secret', () {
    const verifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
    expect(
      codeChallengeS256(verifier),
      'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
    );
    const settings = CognitoPublicSettings(
      hostedDomain: 'https://auth.example.invalid',
      clientId: 'public-client-id-placeholder',
      redirectUri: 'littlegenius://oidc',
    );
    final url = authorizationUrl(
      settings: settings,
      state: 'state-1',
      codeChallenge: codeChallengeS256(verifier),
    );
    expect(url.contains('response_type=code'), isTrue);
    expect(url.contains('code_challenge_method=S256'), isTrue);
    expect(url.contains('client_secret'), isFalse);
    final body = tokenRequestBody(
      clientId: settings.clientId,
      code: 'auth-code',
      codeVerifier: verifier,
      redirectUri: settings.redirectUri,
    );
    expect(body.contains('client_secret'), isFalse);
    expect(settingsFromEnvironment().configured, isFalse);
  });

  test(
    'web refuses refresh tokens and the default phone store is untested',
    () async {
      final source = File('lib/auth/platform_keystore.dart').readAsStringSync();
      expect(source.contains('localStorage'), isFalse);
      expect(source.contains('SharedPreferences'), isFalse);
      final web = keystoreFor(web: true);
      expect(() => web.writeRefreshToken('refresh-token'), throwsStateError);
      expect(await web.readRefreshToken(), isNull);
      final phone = keystoreFor(web: false);
      expect(phone, isA<UnconfiguredPlatformKeystore>());
      expect(() => phone.writeRefreshToken('refresh-token'), throwsStateError);
      final memory = MemoryPlatformKeystore();
      await memory.writeRefreshToken('refresh-token');
      expect(await memory.readRefreshToken(), 'refresh-token');
      await memory.clearRefreshToken();
      expect(await memory.readRefreshToken(), isNull);
    },
  );

  test('conversion uses clientProfileId and cancel leaves the snapshot', () {
    const profile = ChildProfile(
      profileId: '11111111-1111-4111-8111-111111111111',
      nickname: 'Asha',
      avatarId: 'leaf',
      ageBand: '2-3',
      preferredLocale: 'ta',
      bilingualMode: true,
      revision: 1,
    );
    final event = LearningEvent(
      eventId: '22222222-2222-4222-8222-222222222222',
      contentId: 'animal.elephant.001',
      contentVersion: 1,
      eventType: 'completed',
      occurredAt: DateTime.utc(2026, 10, 29),
    );
    expect(
      buildAccountUpload(
        consentGranted: false,
        cognitoConfigured: true,
        profile: profile,
        events: [event],
      ),
      isNull,
    );
    expect(
      buildAccountUpload(
        consentGranted: true,
        cognitoConfigured: false,
        profile: profile,
        events: [event],
      ),
      isNull,
    );
    final plan = buildAccountUpload(
      consentGranted: true,
      cognitoConfigured: true,
      profile: profile,
      events: [event],
    );
    expect(plan?.clientProfileId, profile.profileId);
    expect(plan?.body['clientProfileId'], profile.profileId);
    expect(uploadedFieldNames, contains('nickname'));
    expect(uploadedFieldNames.contains('taps'), isFalse);
    final snapshot = LocalSnapshot(
      profileId: profile.profileId,
      eventIds: [event.eventId],
      outboxBodies: const ['{"events":[]}'],
    );
    expect(identical(snapshot.afterCancel(), snapshot), isTrue);
    final offline = requestDeletion(online: false);
    expect(offline.showsFinished, isFalse);
    expect(
      offline.message,
      'A network connection is required to finish deletion.',
    );
    final pending = requestDeletion(online: true, serverStatus: 'pending');
    expect(pending.showsFinished, isFalse);
    expect(pending.message.contains('not finished'), isTrue);
    final done = requestDeletion(online: true, serverStatus: 'completed');
    expect(done.showsFinished, isTrue);
  });

  testWidgets('cancel leaves the device and web stays local', (tester) async {
    final repository = MemoryLearningRepository();
    final profile = await repository.createProfile(
      const ProfileDraft(
        nickname: 'Asha',
        avatarId: 'leaf',
        ageBand: '2-3',
        preferredLocale: 'en',
        bilingualMode: false,
      ),
    );
    await repository.setActiveProfileId(profile.profileId);
    await repository.applyEvent(
      profileId: profile.profileId,
      categoryId: 'animals',
      event: LearningEvent(
        eventId: 'local-event',
        contentId: 'animal.elephant.001',
        contentVersion: 1,
        eventType: 'completed',
        occurredAt: DateTime.utc(2026, 10, 29),
      ),
    );
    final beforeEvents = await repository.listEvents(profile.profileId);
    final beforeOutbox = await repository.listOutbox(profile.profileId);
    var left = false;

    await tester.pumpWidget(_app(repository, onLeave: () => left = true));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('consent-not-legal')), findsWidgets);
    expect(find.text('This consent is not a legal sign-off.'), findsWidgets);
    expect(find.byKey(const Key('upload-explain')), findsOneWidget);
    expect(find.text(profile.profileId), findsOneWidget);
    await tester.tap(find.byKey(const Key('account-cancel')));
    await tester.pump();
    expect(left, isTrue);
    expect(await repository.listEvents(profile.profileId), beforeEvents);
    expect(await repository.listOutbox(profile.profileId), beforeOutbox);
    expect(await repository.getProfile(profile.profileId), isNotNull);
    expect(beforeOutbox.single.body.contains('http'), isFalse);

    await tester.pumpWidget(_app(repository, web: true));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('web-local-mode')), findsOneWidget);
    expect(find.byKey(const Key('consent-checkbox')), findsNothing);
    expect(
      find.text(
        'This browser stays in local mode. Sign-in is not stored in the browser.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('offline deletion is not shown as finished', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = MemoryLearningRepository();
    final profile = await repository.createProfile(
      const ProfileDraft(
        nickname: 'Asha',
        avatarId: 'star',
        ageBand: '3-4',
        preferredLocale: 'en',
        bilingualMode: false,
      ),
    );
    await repository.setActiveProfileId(profile.profileId);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-delete')));
    await tester.pump();
    expect(
      find.text('A network connection is required to finish deletion.'),
      findsOneWidget,
    );
    expect(find.text('Deletion finished.'), findsNothing);
    expect(await repository.getProfile(profile.profileId), isNotNull);
  });
}

Widget _app(
  MemoryLearningRepository repository, {
  bool web = false,
  VoidCallback? onLeave,
}) {
  return ProviderScope(
    overrides: [repositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      theme: appTheme(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AccountScreen(web: web, onLeave: onLeave),
    ),
  );
}
