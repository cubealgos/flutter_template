import 'package:appwrite_tool/src/table_access.dart';
import 'package:test/test.dart';

const _broadPreFix = TableSettings(
  permissions: <String>[
    'create("users")',
    'read("users")',
    'update("users")',
    'delete("users")',
  ],
  rowSecurity: true,
);

void main() {
  test('pins the exact table-level permissions per TableAccess', () {
    expect(tablePermissions(TableAccess.signedIn), <String>['create("users")']);
    expect(tablePermissions(TableAccess.publicRead), <String>[
      'create("users")',
      'read("any")',
    ]);
    expect(tablePermissions(TableAccess.serverOnly), isEmpty);
  });

  test('a signed-in table never grants read, update or delete', () {
    for (final access in <TableAccess>[
      TableAccess.signedIn,
      TableAccess.publicRead,
    ]) {
      final perms = tablePermissions(access);
      expect(perms, isNot(contains('read("users")')));
      expect(perms.where((p) => p.startsWith('update')), isEmpty);
      expect(perms.where((p) => p.startsWith('delete')), isEmpty);
    }
  });

  test('row security is on', () {
    expect(tableRowSecurity, isTrue);
  });

  test('the pre-fix blanket grant counts as drift', () {
    expect(tableAccessDrifted(_broadPreFix, TableAccess.signedIn), isTrue);
    expect(tableAccessDrifted(_broadPreFix, TableAccess.publicRead), isTrue);
  });

  test('matching settings, in any order, are not drift', () {
    const reordered = TableSettings(
      permissions: <String>['read("any")', 'create("users")'],
      rowSecurity: true,
    );
    expect(tableAccessDrifted(reordered, TableAccess.publicRead), isFalse);
  });

  test('rowSecurity off is drift', () {
    const off = TableSettings(
      permissions: <String>['create("users")'],
      rowSecurity: false,
    );
    expect(tableAccessDrifted(off, TableAccess.signedIn), isTrue);
  });

  test('serverOnly: an empty list is no drift, any grant is', () {
    const empty = TableSettings(permissions: <String>[], rowSecurity: true);
    expect(tableAccessDrifted(empty, TableAccess.serverOnly), isFalse);
    expect(tableAccessDrifted(_broadPreFix, TableAccess.serverOnly), isTrue);
    // And an empty list on a signed-in table is drift: create is missing.
    expect(tableAccessDrifted(empty, TableAccess.signedIn), isTrue);
  });
}
