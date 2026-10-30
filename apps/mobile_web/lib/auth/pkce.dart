import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class CognitoPublicSettings {
  const CognitoPublicSettings({
    required this.hostedDomain,
    required this.clientId,
    required this.redirectUri,
  });

  final String hostedDomain;
  final String clientId;
  final String redirectUri;

  bool get configured =>
      hostedDomain.isNotEmpty && clientId.isNotEmpty && redirectUri.isNotEmpty;
}

CognitoPublicSettings settingsFromEnvironment() {
  return const CognitoPublicSettings(
    hostedDomain: String.fromEnvironment('COGNITO_HOSTED_DOMAIN'),
    clientId: String.fromEnvironment('COGNITO_AUDIENCE'),
    redirectUri: String.fromEnvironment('COGNITO_REDIRECT_URI'),
  );
}

String randomCodeVerifier() {
  final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

String codeChallengeS256(String verifier) {
  final digest = sha256.convert(utf8.encode(verifier));
  return base64UrlEncode(digest.bytes).replaceAll('=', '');
}

String authorizationUrl({
  required CognitoPublicSettings settings,
  required String state,
  required String codeChallenge,
}) {
  final base = Uri.parse(settings.hostedDomain);
  return base
      .replace(
        path: '/oauth2/authorize',
        queryParameters: {
          'response_type': 'code',
          'client_id': settings.clientId,
          'redirect_uri': settings.redirectUri,
          'scope': 'openid',
          'state': state,
          'code_challenge': codeChallenge,
          'code_challenge_method': 'S256',
        },
      )
      .toString();
}

String tokenRequestBody({
  required String clientId,
  required String code,
  required String codeVerifier,
  required String redirectUri,
}) {
  return Uri(
    queryParameters: {
      'grant_type': 'authorization_code',
      'client_id': clientId,
      'code': code,
      'redirect_uri': redirectUri,
      'code_verifier': codeVerifier,
    },
  ).query;
}
