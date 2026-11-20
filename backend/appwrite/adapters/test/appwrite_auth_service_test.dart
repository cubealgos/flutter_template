import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite_adapters/appwrite_adapters.dart';
import 'package:auth/auth.dart';
import 'package:test/test.dart';

import 'fakes/appwrite_model_fixtures.dart';
import 'fakes/fake_account_gateway.dart';

const int _conflict = 409;

/// What `ApiClient` throws for the `delete_account` action's `owns_teams`
/// refusal.
final AppwriteException _ownsTeamsRefusal = AppwriteException(
  'delete_account returned $_conflict: '
  '${jsonEncode(<String, dynamic>{
    'error': <String, dynamic>{
      'code': 'owns_teams',
      'message': 'You own "Acme".',
      'teams': <String>['Acme', 'Beta'],
    },
  })}',
  _conflict,
);

Future<AppwriteAuthService> _signedInWith(FakeAccountGateway gateway) async {
  final service = AppwriteAuthService.withGateway(gateway);
  await service.verifyEmailCode(
    const EmailCodeRequest(userId: 'u1', email: 'a@example.com'),
    'valid-secret',
  );

  return service;
}

void main() {
  group('AppwriteAuthService.restoreSession', () {
    test(
      'returns null and leaves currentSession null with no session',
      () async {
        final service = AppwriteAuthService.withGateway(FakeAccountGateway());

        final resumed = await service.restoreSession();

        expect(resumed, isNull);
        expect(service.currentSession, isNull);
      },
    );

    test('resumes an existing session and updates currentSession', () async {
      final gateway = FakeAccountGateway()
        ..currentUser = fakeUser(id: 'existing-user', email: 'a@b.c');
      final service = AppwriteAuthService.withGateway(gateway);

      final resumed = await service.restoreSession();

      expect(resumed?.userId, 'existing-user');
      expect(resumed?.email, 'a@b.c');
      expect(service.currentSession, resumed);
    });

    test('emits the resumed session on sessionChanges', () async {
      final gateway = FakeAccountGateway()
        ..currentUser = fakeUser(id: 'existing-user');
      final service = AppwriteAuthService.withGateway(gateway);

      final changes = service.sessionChanges;
      final future = changes.first;
      await service.restoreSession();

      expect((await future)?.userId, 'existing-user');
    });
  });

  group('AppwriteAuthService requestEmailCode', () {
    test('never reveals whether the account already existed', () async {
      final gateway = FakeAccountGateway();
      final service = AppwriteAuthService.withGateway(gateway);

      final ok = await service.requestEmailCode('new@example.com');

      expect(ok.email, 'new@example.com');
    });

    test('reuses the existing account for a repeat email', () async {
      // Modeling the real, verified Appwrite behavior: createEmailToken
      // looks the email up first and issues the token for whichever
      // account owns it, regardless of the passed userId - see
      // AppwriteAuthService's "Email-code existence finding" dartdoc.
      final gateway = FakeAccountGateway();
      final service = AppwriteAuthService.withGateway(gateway);

      final first = await service.requestEmailCode('person@example.com');
      final second = await service.requestEmailCode('person@example.com');

      expect(second.userId, first.userId);
    });

    test('propagates a genuine error rather than masking it '
        '(the one narrow case that does reveal existence — see dartdoc)', () {
      final gateway = FakeAccountGateway(errorOnDuplicateEmail: true);
      final service = AppwriteAuthService.withGateway(gateway);

      expect(
        () => service.requestEmailCode('taken@example.com'),
        throwsA(isA<AuthUnknownError>()),
      );
    });

    test('throws AuthUnsupportedError when disabled', () {
      final service = AppwriteAuthService.withGateway(
        FakeAccountGateway(),
        capabilities: const AuthCapabilities(supportsEmailCode: false),
      );

      expect(
        () => service.requestEmailCode('person@example.com'),
        throwsA(isA<AuthUnsupportedError>()),
      );
    });
  });

  group('AppwriteAuthService verifyEmailCode', () {
    test('starts a session on a valid secret', () async {
      final gateway = FakeAccountGateway();
      final service = AppwriteAuthService.withGateway(gateway);
      const request = EmailCodeRequest(userId: 'u1', email: 'a@example.com');

      final session = await service.verifyEmailCode(request, 'valid-secret');

      expect(session.userId, 'u1');
      expect(service.currentSession, session);
    });

    test('maps an invalid secret to AuthInvalidCodeError', () async {
      final gateway = FakeAccountGateway();
      final service = AppwriteAuthService.withGateway(gateway);
      const request = EmailCodeRequest(userId: 'u1', email: 'a@example.com');

      expect(
        () => service.verifyEmailCode(request, 'wrong'),
        throwsA(isA<AuthInvalidCodeError>()),
      );
    });
  });

  group('AppwriteAuthService passkeys', () {
    test('always unsupported', () {
      final service = AppwriteAuthService.withGateway(FakeAccountGateway());

      expect(service.capabilities.supportsPasskeys, isFalse);
      expect(service.signInWithPasskey, throwsA(isA<AuthUnsupportedError>()));
    });
  });

  group('AppwriteAuthService OAuth', () {
    test('signs in via the gateway (no Flutter bindings needed)', () async {
      final gateway = FakeAccountGateway();
      final service = AppwriteAuthService.withGateway(gateway);

      final session = await service.signInWithOAuth(OAuthProvider.google);

      expect(gateway.oauthSessionCreated, isTrue);
      expect(session.email, 'google@example.com');
    });

    test('throws AuthUnsupportedError for a disabled provider', () {
      final service = AppwriteAuthService.withGateway(
        FakeAccountGateway(),
        capabilities: const AuthCapabilities(supportsOAuthApple: true),
      );

      expect(
        () => service.signInWithOAuth(OAuthProvider.google),
        throwsA(isA<AuthUnsupportedError>()),
      );
    });
  });

  group('AppwriteAuthService signInWithReviewCode', () {
    test('exchanges the configured code for a session on the demo '
        'account', () async {
      final gateway = FakeAccountGateway();
      final service = AppwriteAuthService.withGateway(gateway);

      final session = await service.signInWithReviewCode(
        'the-real-review-code',
      );

      expect(session.userId, 'review-demo-user');
      expect(service.currentSession, session);
    });

    test('maps a wrong code to AuthInvalidCodeError, issuing no session', () {
      final gateway = FakeAccountGateway();
      final service = AppwriteAuthService.withGateway(gateway);

      expect(
        () => service.signInWithReviewCode('wrong'),
        throwsA(isA<AuthInvalidCodeError>()),
      );
      expect(gateway.currentUser, isNull);
    });
  });

  group('AppwriteAuthService signOut', () {
    test('is a no-op when already signed out', () async {
      final gateway = FakeAccountGateway();
      final service = AppwriteAuthService.withGateway(gateway);

      await service.signOut();

      expect(gateway.currentSessionDeleted, isFalse);
    });

    test('clears the session and calls the gateway', () async {
      final gateway = FakeAccountGateway();
      final service = AppwriteAuthService.withGateway(gateway);
      await service.verifyEmailCode(
        const EmailCodeRequest(userId: 'u1', email: 'a@example.com'),
        'valid-secret',
      );

      await service.signOut();

      expect(gateway.currentSessionDeleted, isTrue);
      expect(service.currentSession, isNull);
    });
  });

  group('AppwriteAuthService deleteAccount', () {
    test('clears the session once the function deletes the user', () async {
      final gateway = FakeAccountGateway();
      final service = AppwriteAuthService.withGateway(gateway);
      await service.verifyEmailCode(
        const EmailCodeRequest(userId: 'u1', email: 'a@example.com'),
        'valid-secret',
      );

      await service.deleteAccount();

      expect(service.currentSession, isNull);
    });

    test('throws when the function ran but did not delete the user', () async {
      final gateway = FakeAccountGateway()..deleteAccountSucceeds = false;
      final service = AppwriteAuthService.withGateway(gateway);
      await service.verifyEmailCode(
        const EmailCodeRequest(userId: 'u1', email: 'a@example.com'),
        'valid-secret',
      );

      expect(service.deleteAccount, throwsA(isA<AuthUnknownError>()));
    });

    test('requires a session', () {
      final service = AppwriteAuthService.withGateway(FakeAccountGateway());

      expect(service.deleteAccount, throwsA(isA<AuthUnauthenticatedError>()));
    });

    test('maps the owns_teams refusal to AuthOwnsTeamsError, naming the '
        'teams, and keeps the session', () async {
      final service = await _signedInWith(
        FakeAccountGateway()..deleteAccountError = _ownsTeamsRefusal,
      );

      await expectLater(
        service.deleteAccount,
        throwsA(
          isA<AuthOwnsTeamsError>().having(
            (e) => e.teamNames,
            'teamNames',
            <String>['Acme', 'Beta'],
          ),
        ),
      );
      expect(service.currentSession, isNotNull);
    });

    test('maps any other 409 to AuthUnknownError', () async {
      final service = await _signedInWith(
        FakeAccountGateway()
          ..deleteAccountError = AppwriteException(
            'delete_account returned $_conflict: x',
            _conflict,
          ),
      );

      expect(service.deleteAccount, throwsA(isA<AuthUnknownError>()));
    });
  });

  group('AppwriteAuthService identities', () {
    test('lists and unlinks', () async {
      final gateway = FakeAccountGateway();
      final service = AppwriteAuthService.withGateway(gateway);
      await service.verifyEmailCode(
        const EmailCodeRequest(userId: 'u1', email: 'a@example.com'),
        'valid-secret',
      );

      final identities = await service.listIdentities();
      await service.unlinkIdentity(identities.single.id);

      expect(identities.single.provider, 'google');
      expect(gateway.deletedIdentityIds, <String>[identities.single.id]);
    });

    test('requires a session', () {
      final service = AppwriteAuthService.withGateway(FakeAccountGateway());

      expect(service.listIdentities, throwsA(isA<AuthUnauthenticatedError>()));
    });
  });
}
