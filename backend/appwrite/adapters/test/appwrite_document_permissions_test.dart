import 'package:appwrite_adapters/appwrite_adapters.dart';
import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a user scope grants only that user', () {
    expect(appwritePermissionsFor(const UserScope(), 'u1'), <String>[
      'read("user:u1")',
      'update("user:u1")',
      'delete("user:u1")',
    ]);
  });

  test('a team scope without roles grants every member', () {
    expect(appwritePermissionsFor(const TeamScope('t1'), 'u1'), <String>[
      'read("team:t1")',
      'update("team:t1")',
      'delete("team:t1")',
    ]);
  });

  test('a role-scoped team row grants only that team role', () {
    final permissions = appwritePermissionsFor(
      const TeamScope('t1', readRoles: <String>{'admin'}),
      'u1',
    );

    expect(permissions, <String>[
      'read("team:t1/admin")',
      'update("team:t1/admin")',
      'delete("team:t1/admin")',
    ]);
  });

  test('members read, admins write', () {
    final permissions = appwritePermissionsFor(
      const TeamScope(
        't1',
        readRoles: <String>{'member'},
        writeRoles: <String>{'admin'},
      ),
      'u1',
    );

    expect(permissions, <String>[
      'read("team:t1/member")',
      'update("team:t1/admin")',
      'delete("team:t1/admin")',
    ]);
  });

  test('the owner role is the native tenant owner, never "owner"', () {
    final permissions = appwritePermissionsFor(
      const TeamScope('t1', readRoles: <String>{'owner'}),
      'u1',
    );

    expect(permissions.first, 'read("team:t1/$nativeOwnerRole")');
    expect(permissions.join(), isNot(contains('team:t1/owner')));
  });

  test('no team scope ever mentions a user or Role.any', () {
    final permissions = appwritePermissionsFor(const TeamScope('t1'), 'u1');

    expect(permissions.join(), isNot(contains('user:')));
    expect(permissions.join(), isNot(contains('any')));
  });
}
