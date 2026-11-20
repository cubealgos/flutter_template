import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as enums;
import 'package:appwrite/models.dart' as models;
import 'package:appwrite_adapters/src/account_gateway.dart';
import 'package:appwrite_adapters/src/api_client.dart';

/// The real [AccountGateway], backed by `package:appwrite`'s `Account` service
/// and, for server-side actions, the `api` router Function through
/// [ApiClient].
class AppwriteAccountGateway implements AccountGateway {
  /// Creates a gateway backed by [client].
  AppwriteAccountGateway(Client client)
    : _account = Account(client),
      _api = ApiClient(Functions(client));

  final Account _account;
  final ApiClient _api;

  @override
  Future<models.User> getCurrentUser() => _account.get();

  @override
  Future<models.Token> createEmailToken({
    required String userId,
    required String email,
  }) => _account.createEmailToken(userId: userId, email: email);

  @override
  Future<models.Session> createSessionFromToken({
    required String userId,
    required String secret,
  }) => _account.createSession(userId: userId, secret: secret);

  @override
  Future<String> executeReviewDemoSignInFunction(String code) =>
      _api.call('review_demo_sign_in', fields: <String, dynamic>{'code': code});

  @override
  Future<void> createOAuth2Session(enums.OAuthProvider provider) async {
    await _account.createOAuth2Session(provider: provider);
  }

  @override
  Future<void> deleteCurrentSession() async {
    await _account.deleteSession(sessionId: 'current');
  }

  @override
  Future<models.IdentityList> listIdentities() => _account.listIdentities();

  @override
  Future<void> deleteIdentity(String identityId) async {
    await _account.deleteIdentity(identityId: identityId);
  }

  @override
  Future<models.Preferences> getPrefs() => _account.getPrefs();

  @override
  Future<models.User> updatePrefs(Map<String, dynamic> prefs) =>
      _account.updatePrefs(prefs: prefs);

  @override
  Future<String> executeDeleteAccountFunction() => _api.call('delete_account');
}

/// Decodes a Function's JSON response body — a thin `jsonDecode` wrapper so
/// callers don't need their own `dart:convert` import just for this.
Map<String, dynamic> decodeFunctionResponse(String responseBody) =>
    jsonDecode(responseBody) as Map<String, dynamic>;
