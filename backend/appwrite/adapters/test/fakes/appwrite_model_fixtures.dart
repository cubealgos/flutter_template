import 'package:appwrite/models.dart' as models;

/// Builders for the `package:appwrite` model types these tests need,
/// filling every field this package doesn't care about with an inert
/// placeholder — those SDK models have dozens of required fields (device,
/// OS, MFA metadata, …) that are noise for testing this adapter's own
/// logic (capability gating, session-stream updates, error mapping), not
/// signal.

/// Builds a minimal [models.User] for [id]/[email].
models.User fakeUser({required String id, String email = ''}) => models.User(
  $id: id,
  $createdAt: '',
  $updatedAt: '',
  name: '',
  registration: '',
  status: true,
  labels: const <String>[],
  passwordUpdate: '',
  email: email,
  phone: '',
  emailVerification: false,
  phoneVerification: false,
  mfa: false,
  prefs: models.Preferences(data: const <String, dynamic>{}),
  targets: const <models.Target>[],
  accessedAt: '',
);

/// Builds a minimal [models.Session] for [userId].
models.Session fakeSession({required String userId}) => models.Session(
  $id: 'fake-session',
  $createdAt: '',
  $updatedAt: '',
  userId: userId,
  expire: '',
  provider: '',
  providerUid: '',
  providerAccessToken: '',
  providerAccessTokenExpiry: '',
  providerRefreshToken: '',
  ip: '',
  osCode: '',
  osName: '',
  osVersion: '',
  clientType: '',
  clientCode: '',
  clientName: '',
  clientVersion: '',
  clientEngine: '',
  clientEngineVersion: '',
  deviceName: '',
  deviceBrand: '',
  deviceModel: '',
  countryCode: '',
  countryName: '',
  current: true,
  factors: const <String>[],
  secret: '',
  mfaUpdatedAt: '',
);

/// Builds a minimal [models.Token] for [userId].
models.Token fakeToken({required String userId}) => models.Token(
  $id: 'fake-token',
  $createdAt: '',
  userId: userId,
  secret: '',
  expire: '',
  phrase: '',
);

/// Builds a [models.IdentityList] with one identity for [provider].
models.IdentityList fakeIdentityList({
  required String id,
  required String userId,
  required String provider,
  String providerEmail = '',
}) => models.IdentityList(
  total: 1,
  identities: <models.Identity>[
    models.Identity(
      $id: id,
      $createdAt: '',
      $updatedAt: '',
      userId: userId,
      provider: provider,
      providerUid: '',
      providerEmail: providerEmail,
      providerAccessToken: '',
      providerAccessTokenExpiry: '',
      providerRefreshToken: '',
    ),
  ],
);

/// Builds a minimal completed [models.Execution] of the `api` Function with
/// the given response [status] and [body].
models.Execution fakeExecution({required int status, required String body}) =>
    models.Execution.fromMap(<String, dynamic>{
      r'$id': 'e',
      r'$createdAt': '',
      r'$updatedAt': '',
      r'$permissions': <String>[],
      'resourceId': 'api',
      'resourceType': 'functions',
      'deploymentId': 'd',
      'trigger': 'http',
      'status': 'completed',
      'requestMethod': 'POST',
      'requestPath': '/',
      'requestHeaders': <Map<String, String>>[],
      'responseStatusCode': status,
      'responseBody': body,
      'responseHeaders': <Map<String, String>>[],
      'logs': '',
      'errors': '',
      'duration': 0.1,
    });
