import 'dart:convert';

import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/backend_env.dart';
import 'package:dart_appwrite/dart_appwrite.dart' as appwrite;
import 'package:http/http.dart' as http;

/// A real Appwrite user, admin-created with no password
/// (`Provisioner` disables the project's `email-password` auth method
/// entirely — see its `unusedAuthMethods` dartdoc — so the public
/// `/account` sign-up endpoint this class used before is refused now) and
/// logged in through a real session via an admin-issued OTP token, exactly
/// how this template's own email-OTP sign-in flow ends
/// (`AppwriteAuthService.verifyEmailCode`) — not a password-based
/// shortcut, since this template has none.
class TestUser {
  const TestUser({
    required this.userId,
    required this.email,
    required this.sessionCookie,
    required this.adminEnv,
  });

  /// The created user's Appwrite ID.
  final String userId;

  /// The email the user was created with.
  final String email;

  /// The `Cookie` header value for this user's logged-in session.
  final String sessionCookie;

  /// Admin config, used only by [deleteIfStillPresent]'s cleanup.
  final BackendEnv adminEnv;

  /// Creates and logs in a fresh test user against [env]'s endpoint and
  /// project, using [adminClient] (API-key-authenticated) for the
  /// admin-only `Users.create`/`Users.createToken` calls.
  static Future<TestUser> create(
    BackendEnv env,
    appwrite.Client adminClient,
  ) async {
    final email =
        'integration-${DateTime.now().millisecondsSinceEpoch}@example.com';

    final users = appwrite.Users(adminClient);
    final user = await users.create(
      userId: appwrite.ID.unique(),
      email: email,
      name: 'Integration Test',
    );
    final token = await users.createToken(userId: user.$id);
    final sessionCookie = await _exchangeTokenForSession(
      env,
      userId: user.$id,
      secret: token.secret,
    );

    return TestUser(
      userId: user.$id,
      email: email,
      sessionCookie: sessionCookie,
      adminEnv: env,
    );
  }

  static Future<String> _exchangeTokenForSession(
    BackendEnv env, {
    required String userId,
    required String secret,
  }) async {
    final sessionResponse = await http.post(
      Uri.parse('${env.endpoint}/account/sessions/token'),
      headers: _projectHeaders(env),
      body: jsonEncode(<String, dynamic>{'userId': userId, 'secret': secret}),
    );
    final rawCookies = sessionResponse.headers['x-fallback-cookies'] ?? '{}';
    final fallbackCookies = jsonDecode(rawCookies) as Map<String, dynamic>;
    final cookiePair = fallbackCookies.entries.single;

    return '${cookiePair.key}=${cookiePair.value}';
  }

  static Map<String, String> _projectHeaders(BackendEnv env) =>
      <String, String>{
        'X-Appwrite-Project': env.projectId,
        'Content-Type': 'application/json',
      };

  /// Creates a `profiles` row owned by this user (see
  /// `TableOwnership.userIdColumn`), so `delete_account` has something to
  /// find and delete.
  Future<void> createOwnedProfileRow(appwrite.Client adminClient) async {
    final tablesDb = appwrite.TablesDB(adminClient);
    await tablesDb.createRow(
      databaseId: templateSchema.databaseId,
      tableId: 'profiles',
      rowId: appwrite.ID.unique(),
      data: <String, dynamic>{'userId': userId, 'displayName': 'Integration'},
      permissions: <String>[
        appwrite.Permission.read(appwrite.Role.user(userId)),
        appwrite.Permission.delete(appwrite.Role.user(userId)),
      ],
    );
  }

  /// Executes the `api` Function's `delete_account` action as this user and
  /// returns the decoded `AccountDeletionResult` JSON body.
  Future<Map<String, dynamic>> executeDeleteAccount(BackendEnv env) async {
    final response = await http.post(
      Uri.parse('${env.endpoint}/functions/api/executions'),
      headers: <String, String>{
        'X-Appwrite-Project': env.projectId,
        'Cookie': sessionCookie,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'async': false,
        'body': jsonEncode(<String, dynamic>{'action': 'delete_account'}),
        'headers': <String, String>{'content-type': 'application/json'},
      }),
    );
    final execution = jsonDecode(response.body) as Map<String, dynamic>;
    final body = execution['responseBody'] as String? ?? '{}';

    return jsonDecode(body.isEmpty ? '{}' : body) as Map<String, dynamic>;
  }

  /// Best-effort cleanup if the test's assertions failed before the
  /// function itself deleted the user - keeps repeated local runs from
  /// accumulating stray accounts.
  Future<void> deleteIfStillPresent(appwrite.Client adminClient) async {
    final users = appwrite.Users(adminClient);
    try {
      await users.delete(userId: userId);
    } on appwrite.AppwriteException {
      // Already gone - the happy path.
    }
  }
}
