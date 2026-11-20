// Test literals are plain in a test.
// ignore_for_file: solid_lints/no_magic_number

import 'package:api/src/billing/appwrite_billing_access.dart';
import 'package:billing/billing.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:test/test.dart';

void main() {
  const team = BillingOwner.team('t1');

  AppwriteBillingAccess access(
    Future<List<String>?> Function(String, String) f,
  ) => AppwriteBillingAccess.withLookup(f);

  test('an unknown team (Appwrite answers team_not_found, 404) is a '
      'non-member: nobody may read or manage', () async {
    final a = access(
      (_, _) async => throw AppwriteException('team_not_found', 404),
    );

    expect(await a.mayRead('u1', team), isFalse);
    expect(await a.mayManage('u1', team), isFalse);
  });

  test(
    'a real team the caller is not in lists no membership: refused',
    () async {
      final a = access((_, _) async => null);

      expect(await a.mayRead('u1', team), isFalse);
    },
  );

  test('members read; only an owner or admin manages', () async {
    expect(await access((_, _) async => ['member']).mayRead('u', team), isTrue);
    expect(
      await access((_, _) async => ['member']).mayManage('u', team),
      isFalse,
    );
    expect(
      await access((_, _) async => ['admin', 'member']).mayManage('u', team),
      isTrue,
    );
    expect(
      await access((_, _) async => ['tenant_owner']).mayManage('u', team),
      isTrue,
    );
  });

  test('a genuine failure (not a 404) still propagates', () async {
    final a = access((_, _) async => throw AppwriteException('boom', 500));

    await expectLater(a.mayRead('u', team), throwsA(isA<AppwriteException>()));
  });

  test('a user acts only for themselves', () async {
    final a = access((_, _) async => throw StateError('not asked'));

    expect(await a.mayManage('u1', const BillingOwner.user('u1')), isTrue);
    expect(await a.mayRead('u1', const BillingOwner.user('u2')), isFalse);
  });
}
