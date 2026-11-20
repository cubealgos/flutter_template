import 'package:auth/auth.dart';
import 'package:test/test.dart';

void main() {
  group('FakeAuthService.restoreSession', () {
    test('returns null when nothing is persisted', () async {
      final service = FakeAuthService();

      expect(await service.restoreSession(), isNull);
      expect(service.currentSession, isNull);
    });

    test('resumes a persisted session and updates currentSession', () async {
      const session = AuthSession(userId: 'restored-user', email: 'a@b.c');
      final service = FakeAuthService(persistedSession: session);

      final resumed = await service.restoreSession();

      expect(resumed, session);
      expect(service.currentSession, session);
    });

    test('only resumes once', () async {
      const session = AuthSession(userId: 'restored-user');
      final service = FakeAuthService(persistedSession: session);

      await service.restoreSession();
      await service.signOut();
      final secondAttempt = await service.restoreSession();

      expect(secondAttempt, isNull);
    });

    test('an already-current session is returned as-is', () async {
      final service = FakeAuthService();
      final request = await service.requestEmailCode('a@b.c');
      final session = await service.verifyEmailCode(
        request,
        FakeAuthService.fixedEmailCode,
      );

      expect(await service.restoreSession(), session);
    });
  });

  group('FakeAuthService email code', () {
    test('never reveals whether the account already existed', () async {
      final service = FakeAuthService();

      final first = await service.requestEmailCode('new@example.com');
      final second = await service.requestEmailCode('new@example.com');

      // Same shape (same userId, same email) whether this was the first
      // request for this address or a repeat - nothing in the returned
      // value lets a caller tell "new" from "existing" apart.
      expect(second.userId, first.userId);
      expect(second.email, first.email);
    });

    test('verifies the fixed code and starts a session', () async {
      final service = FakeAuthService();
      final request = await service.requestEmailCode('person@example.com');

      final session = await service.verifyEmailCode(
        request,
        FakeAuthService.fixedEmailCode,
      );

      expect(session.userId, request.userId);
      expect(session.email, 'person@example.com');
      expect(service.currentSession, session);
    });

    test('rejects a wrong code', () async {
      final service = FakeAuthService();
      final request = await service.requestEmailCode('person@example.com');

      expect(
        () => service.verifyEmailCode(request, 'wrong'),
        throwsA(isA<AuthInvalidCodeError>()),
      );
      expect(service.currentSession, isNull);
    });

    test('rejects verifying without a matching pending request', () async {
      final service = FakeAuthService();

      expect(
        () => service.verifyEmailCode(
          const EmailCodeRequest(userId: 'nope', email: 'nope@example.com'),
          FakeAuthService.fixedEmailCode,
        ),
        throwsA(isA<AuthInvalidCodeError>()),
      );
    });

    test('throws AuthUnsupportedError when disabled', () async {
      final service = FakeAuthService(
        capabilities: const AuthCapabilities(supportsEmailCode: false),
      );

      expect(
        () => service.requestEmailCode('person@example.com'),
        throwsA(isA<AuthUnsupportedError>()),
      );
    });
  });

  group('FakeAuthService sessionChanges', () {
    test('emits on sign-in and sign-out', () async {
      final service = FakeAuthService();
      final events = <AuthSession?>[];
      final subscription = service.sessionChanges.listen(events.add);
      addTearDown(subscription.cancel);

      final session = await service.signInWithPasskey();
      await service.signOut();
      await Future<void>.delayed(Duration.zero);

      expect(events, <AuthSession?>[session, null]);
    });

    test('signOut is a no-op when already signed out', () async {
      final service = FakeAuthService();

      await service.signOut();

      expect(service.currentSession, isNull);
    });
  });

  group('FakeAuthService passkeys', () {
    test('defaults to supported for this fake', () async {
      final service = FakeAuthService();

      final session = await service.signInWithPasskey();

      expect(service.capabilities.supportsPasskeys, isTrue);
      expect(session.email, isNull);
    });

    test('throws AuthUnsupportedError when disabled', () {
      final service = FakeAuthService(capabilities: const AuthCapabilities());

      expect(service.signInWithPasskey, throwsA(isA<AuthUnsupportedError>()));
    });
  });

  group('FakeAuthService OAuth', () {
    test('signs in and links an identity per provider', () async {
      final service = FakeAuthService();

      final session = await service.signInWithOAuth(OAuthProvider.google);

      expect(session.email, isNotNull);
      final identities = await service.listIdentities();
      expect(identities, hasLength(1));
      expect(identities.single.provider, 'google');
    });

    test('throws AuthUnsupportedError for a disabled provider', () {
      final service = FakeAuthService(
        capabilities: const AuthCapabilities(supportsOAuthApple: true),
      );

      expect(
        () => service.signInWithOAuth(OAuthProvider.google),
        throwsA(isA<AuthUnsupportedError>()),
      );
    });
  });

  group('FakeAuthService identities', () {
    test('requires a session', () {
      final service = FakeAuthService();

      expect(service.listIdentities, throwsA(isA<AuthUnauthenticatedError>()));
    });

    test('unlinkIdentity removes the matching identity', () async {
      final service = FakeAuthService();
      await service.signInWithOAuth(OAuthProvider.apple);
      final before = await service.listIdentities();

      await service.unlinkIdentity(before.single.id);
      final after = await service.listIdentities();

      expect(after, isEmpty);
    });
  });

  group('FakeAuthService signInWithReviewCode', () {
    test('signs in with the configured demo code', () async {
      final service = FakeAuthService(reviewDemoCode: 'the-real-code');

      final session = await service.signInWithReviewCode('the-real-code');

      expect(session.userId, FakeAuthService.reviewDemoUserId);
      expect(service.currentSession, session);
    });

    test('rejects a wrong code', () async {
      final service = FakeAuthService(reviewDemoCode: 'the-real-code');

      expect(
        () => service.signInWithReviewCode('wrong'),
        throwsA(isA<AuthInvalidCodeError>()),
      );
    });

    test('throws AuthUnsupportedError when no demo account is configured', () {
      final service = FakeAuthService();

      expect(
        () => service.signInWithReviewCode('anything'),
        throwsA(isA<AuthUnsupportedError>()),
      );
    });
  });

  group('FakeAuthService deleteAccount', () {
    test('clears the session and forgets the account', () async {
      final service = FakeAuthService();
      final request = await service.requestEmailCode('gone@example.com');
      await service.verifyEmailCode(request, FakeAuthService.fixedEmailCode);

      await service.deleteAccount();

      expect(service.currentSession, isNull);
      // A fresh request for the same email now gets a new userId - the
      // old account, and its pending state, are really gone.
      final newRequest = await service.requestEmailCode('gone@example.com');
      expect(newRequest.userId, isNot(request.userId));
    });

    test('requires a session', () {
      final service = FakeAuthService();

      expect(service.deleteAccount, throwsA(isA<AuthUnauthenticatedError>()));
    });

    test('is refused, naming the teams, while the user owns any', () async {
      final service = FakeAuthService(
        ownedTeamNames: (_) async => <String>['Acme', 'Beta'],
      );
      await service.signInWithPasskey();

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

    test('goes through and notifies when the user owns no team', () async {
      final deleted = <String>[];
      final service = FakeAuthService(
        ownedTeamNames: (_) async => <String>[],
        onAccountDeleted: (userId) async => deleted.add(userId),
      );
      final session = await service.signInWithPasskey();

      await service.deleteAccount();

      expect(service.currentSession, isNull);
      expect(deleted, <String>[session.userId]);
    });
  });
}
