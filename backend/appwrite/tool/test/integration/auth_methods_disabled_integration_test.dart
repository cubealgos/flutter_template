// Runs against a real Appwrite Cloud dev project (`backend/appwrite/tool/.env.local`
// pointing at it — see
// `backend/appwrite/README.md`). Tagged `integration` so it's excluded from `melos
// run test`'s default `dart test` invocation and only runs via `melos run
// test:integration`.
//
// Proves the account-takeover finding `Provisioner.unusedAuthMethods`
// closes is actually closed against a real Appwrite instance:
// after provisioning, the public email/password sign-up and sign-in
// endpoints are refused outright — not just "wrong password", genuinely
// disabled. Also proves the guest-mode removal reaches the backend,
// not just the app: the public anonymous-session endpoint is refused the
// same way. This template's own email-OTP flow keeps working throughout.
//
// `@Timeout` raised from `dart test`'s 30s default — see
// `delete_account_integration_test.dart`'s identical note: this file's own
// `Provisioner.run()` call runs concurrently with two other files' Function
// deployments against the same Cloud project.
@Timeout(Duration(minutes: 3))
@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/appwrite_client.dart';
import 'package:appwrite_tool/src/backend_env.dart';
import 'package:appwrite_tool/src/dart_appwrite_admin.dart';
import 'package:appwrite_tool/src/provisioner.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  test('the account-takeover path is closed: public email/password sign-up '
      'and sign-in are both refused after provisioning, live', () async {
    final env = BackendEnv.load();
    final client = buildClient(env);
    final admin = DartAppwriteAdmin(client);
    await Provisioner(admin: admin, schema: templateSchema).run();

    await _assertUnusedMethodsDisabled(admin);
    await _assertPasswordSignUpRefused(env);
    await _assertPasswordSignInRefused(env);
    await _assertAnonymousSessionRefused(env);
    await _assertEmailOtpStillWorks(env);
  }, tags: 'integration');
}

Future<void> _assertUnusedMethodsDisabled(DartAppwriteAdmin admin) async {
  final enabled = await admin.enabledAuthMethods();
  for (final methodId in unusedAuthMethods) {
    expect(
      enabled.contains(methodId),
      isFalse,
      reason: '"$methodId" should be disabled after provisioning',
    );
  }
  expect(enabled, contains('email-otp'));
}

/// The exact attack this closes: an attacker pre-creating an account for an
/// arbitrary (victim's) email with a chosen password via the public
/// sign-up endpoint - no API key, exactly what any client can reach.
Future<void> _assertPasswordSignUpRefused(BackendEnv env) async {
  final response = await http.post(
    Uri.parse('${env.endpoint}/account'),
    headers: _projectHeaders(env),
    body: jsonEncode(<String, dynamic>{
      'userId': 'unique()',
      'email': 'attacker-precreated-${_uniqueSuffix()}@example.com',
      'password': 'AttackerChosenPassword123!',
    }),
  );
  expect(
    _isSuccessStatus(response.statusCode),
    isFalse,
    reason:
        'account creation with a password should be refused: '
        '${response.body}',
  );
}

/// Sign-in with a password is refused too, not just sign-up - even for an
/// account that (hypothetically) already had one from before this policy
/// took effect.
Future<void> _assertPasswordSignInRefused(BackendEnv env) async {
  final response = await http.post(
    Uri.parse('${env.endpoint}/account/sessions/email'),
    headers: _projectHeaders(env),
    body: jsonEncode(<String, dynamic>{
      'email': 'nobody-${_uniqueSuffix()}@example.com',
      'password': 'AnyPassword123!',
    }),
  );
  expect(
    _isSuccessStatus(response.statusCode),
    isFalse,
    reason: 'password sign-in should be refused: ${response.body}',
  );
}

/// Guest mode (anonymous sessions) was removed from the template entirely
/// — `AuthService` has no `signInAnonymously` any more, and
/// `Provisioner.unusedAuthMethods` now disables Appwrite's `anonymous`
/// auth method alongside the password-based ones. Genuinely disabled, not
/// just unused by this template's own client code: the public endpoint
/// itself is refused, the same `501 user_auth_method_unsupported` shape
/// Appwrite returns for any auth method turned off project-wide (see
/// `backend/appwrite/README.md`'s "Verified live" note).
Future<void> _assertAnonymousSessionRefused(BackendEnv env) async {
  final response = await http.post(
    Uri.parse('${env.endpoint}/account/sessions/anonymous'),
    headers: _projectHeaders(env),
  );
  expect(
    response.statusCode,
    HttpStatus.notImplemented,
    reason: 'anonymous sign-in should be refused: ${response.body}',
  );
  final body = jsonDecode(response.body) as Map<String, dynamic>;
  expect(body['type'], 'user_auth_method_unsupported');
}

/// The legitimate flow this template actually ships (email OTP) keeps
/// working - this policy is scoped to what the template doesn't use, not
/// a blanket lockout.
Future<void> _assertEmailOtpStillWorks(BackendEnv env) async {
  final response = await http.post(
    Uri.parse('${env.endpoint}/account/tokens/email'),
    headers: _projectHeaders(env),
    body: jsonEncode(<String, dynamic>{
      'userId': 'unique()',
      'email': 'otp-user-${_uniqueSuffix()}@example.com',
    }),
  );
  expect(
    _isSuccessStatus(response.statusCode),
    isTrue,
    reason: 'email OTP should still work: ${response.body}',
  );
}

Map<String, String> _projectHeaders(BackendEnv env) => <String, String>{
  'X-Appwrite-Project': env.projectId,
  'Content-Type': 'application/json',
};

bool _isSuccessStatus(int statusCode) =>
    statusCode >= HttpStatus.ok && statusCode < HttpStatus.multipleChoices;

String _uniqueSuffix() => DateTime.now().millisecondsSinceEpoch.toString();
