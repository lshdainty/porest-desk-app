/// OAuth 2.0 PKCE (RFC 7636) 보조 함수 모음.
///
/// flutter_appauth 가 내부에서 자동 생성하던 code_verifier / code_challenge / state 를,
/// 인앱 WebView 흐름에서는 앱이 직접 만들어 SSO `/oauth2/authorize` 쿼리에 싣는다.
/// 교환(`/auth/exchange-code`)은 같은 code_verifier 를 BFF 로 넘겨 검증한다.
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// 암호학적으로 안전한 난수 [length] 바이트 → padding 없는 base64url 문자열.
String _randomBase64Url(int length) {
  final rng = Random.secure();
  final bytes = List<int>.generate(length, (_) => rng.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

/// PKCE code_verifier 생성. 32바이트 난수 → base64url(no padding) = 43자
/// (RFC 7636 허용 범위 43~128자, 문자셋 [A-Za-z0-9-._~]).
String generateCodeVerifier() => _randomBase64Url(32);

/// code_verifier → code_challenge (S256).
/// `base64url(sha256(ascii(verifier)))`, padding 제거.
String codeChallengeS256(String verifier) {
  final digest = sha256.convert(ascii.encode(verifier));
  return base64UrlEncode(digest.bytes).replaceAll('=', '');
}

/// CSRF 방지용 state 생성. 16바이트 난수 → base64url(no padding).
String generateState() => _randomBase64Url(16);
