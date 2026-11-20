import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as enums;
import 'package:appwrite/models.dart' as models;
import 'package:appwrite_adapters/appwrite_adapters.dart';

import 'appwrite_model_fixtures.dart';

/// The HTTP status this fake throws for "no session".
const int _unauthorizedStatusCode = 401;

/// The HTTP status real Appwrite throws for the one genuine
/// existence-revealing case `createEmailToken` has — see
/// `errorOnDuplicateEmail`'s dartdoc.
const int _badRequestStatusCode = 400;

/// An in-memory [AccountGateway] for `AppwriteAuthService` unit tests — no
/// live Appwrite instance, and no Flutter platform bindings (which the
/// real `createOAuth2Session` needs), required.
class FakeAccountGateway implements AccountGateway {
  /// Creates a fake gateway. [reviewDemoCode]/[reviewDemoUserId] configure
  /// what [executeReviewDemoSignInFunction] accepts and returns, modeling
  /// the `review_demo_sign_in` Function `backend/appwrite/tool/bin/seed_review_demo_account
  /// .dart` configures in a real backend.
  FakeAccountGateway({
    this.errorOnDuplicateEmail = false,
    this.reviewDemoCode = 'the-real-review-code',
    this.reviewDemoUserId = 'review-demo-user',
  });

  /// Whether [createEmailToken] throws a `general_bad_request`-shaped
  /// [AppwriteException] instead of succeeding — simulates real
  /// Appwrite's one narrow existence-revealing case: an email already
  /// attached only to a linked OAuth identity (see
  /// `AppwriteAuthService`'s "Email-code existence finding" dartdoc).
  /// Ordinary account reuse (the common case) is modeled by
  /// [_userIdByEmail] instead and never errors.
  bool errorOnDuplicateEmail;

  /// Whether `executeDeleteAccountFunction`'s `userDeleted` should be
  /// false — simulates the Function running but not fully deleting.
  bool deleteAccountSucceeds = true;

  /// If set, `executeDeleteAccountFunction` throws this (an action's own
  /// refusal as `ApiClient` reports it).
  AppwriteException? deleteAccountError;

  /// The code [executeReviewDemoSignInFunction] accepts.
  String reviewDemoCode;

  /// The user ID [executeReviewDemoSignInFunction] issues a token for on a
  /// matching code.
  String reviewDemoUserId;

  models.User? currentUser;
  final List<String> deletedIdentityIds = <String>[];
  final Map<String, String> _userIdByEmail = <String, String>{};
  bool oauthSessionCreated = false;
  bool currentSessionDeleted = false;

  /// The in-memory preferences store backing [getPrefs]/[updatePrefs] —
  /// exposed mutable so a test can seed a starting value.
  Map<String, dynamic> prefs = <String, dynamic>{};

  @override
  Future<models.User> getCurrentUser() async {
    final user = currentUser;
    if (user == null) {
      throw AppwriteException(
        'No session.',
        _unauthorizedStatusCode,
        'general_unauthorized',
      );
    }

    return user;
  }

  @override
  Future<models.Token> createEmailToken({
    required String userId,
    required String email,
  }) async {
    if (errorOnDuplicateEmail) {
      throw AppwriteException(
        'This email is already linked to another identity.',
        _badRequestStatusCode,
        'general_bad_request',
      );
    }

    // Real Appwrite looks up by email, not by the given [userId] - see
    // `AppwriteAuthService`'s dartdoc. A repeat email reuses the same
    // (originally passed-in) userId; a new one is remembered from here on.
    final resolvedUserId = _userIdByEmail.putIfAbsent(email, () => userId);

    return fakeToken(userId: resolvedUserId);
  }

  @override
  Future<models.Session> createSessionFromToken({
    required String userId,
    required String secret,
  }) async {
    if (secret != 'valid-secret') {
      throw AppwriteException(
        'Invalid token secret.',
        _unauthorizedStatusCode,
        'user_invalid_token',
      );
    }
    currentUser = fakeUser(id: userId);

    return fakeSession(userId: userId);
  }

  @override
  Future<String> executeReviewDemoSignInFunction(String code) async {
    if (code != reviewDemoCode) {
      throw AppwriteException(
        'Invalid review code.',
        _unauthorizedStatusCode,
        'general_unauthorized',
      );
    }

    return jsonEncode(<String, dynamic>{
      'userId': reviewDemoUserId,
      'secret': 'valid-secret',
    });
  }

  @override
  Future<void> createOAuth2Session(enums.OAuthProvider provider) async {
    oauthSessionCreated = true;
    currentUser = fakeUser(
      id: 'oauth-${provider.value}',
      email: '${provider.value}@example.com',
    );
  }

  @override
  Future<void> deleteCurrentSession() async {
    currentSessionDeleted = true;
  }

  @override
  Future<models.IdentityList> listIdentities() async {
    final user = await getCurrentUser();

    return fakeIdentityList(
      id: 'identity-${user.$id}',
      userId: user.$id,
      provider: 'google',
    );
  }

  @override
  Future<void> deleteIdentity(String identityId) async {
    deletedIdentityIds.add(identityId);
  }

  @override
  Future<models.Preferences> getPrefs() async =>
      models.Preferences(data: Map<String, dynamic>.of(prefs));

  @override
  Future<models.User> updatePrefs(Map<String, dynamic> newPrefs) async {
    prefs = Map<String, dynamic>.of(newPrefs);
    final user = currentUser ?? fakeUser(id: 'fake-user');

    return fakeUser(id: user.$id, email: user.email);
  }

  @override
  Future<String> executeDeleteAccountFunction() async {
    final error = deleteAccountError;
    if (error != null) throw error;

    return jsonEncode(<String, dynamic>{
      'userId': currentUser?.$id ?? 'unknown',
      'deletedAt': DateTime.utc(2026).toIso8601String(),
      'userDeleted': deleteAccountSucceeds,
      'removedRows': <String, int>{},
      'removedFiles': <String, int>{},
    });
  }
}
