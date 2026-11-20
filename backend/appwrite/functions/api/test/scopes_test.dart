import 'package:api/src/registry.dart';
import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:test/test.dart';

void main() {
  test("the api Function's declared scopes are exactly the union of its "
      "actions' (and jobs') scopes", () {
    final declared = templateSchema.functions
        .singleWhere((function) => function.id == 'api')
        .scopes
        .toSet();

    expect(
      declared.difference(requiredScopes),
      isEmpty,
      reason:
          'declared on the Function but needed by no action: least '
          'privilege - drop them from backend/appwrite/schema or give them '
          'to the action that needs them',
    );
    expect(
      requiredScopes.difference(declared),
      isEmpty,
      reason:
          'an action needs scopes the Function does not declare: add them '
          'to the `api` FunctionSchema in backend/appwrite/schema',
    );
  });

  test('every action declares a unique snake_case name', () {
    final names = actions.map((action) => action.name).toList();

    expect(names.toSet().length, names.length);
    for (final name in names) {
      expect(name, matches(RegExp(r'^[a-z][a-z0-9_]*$')));
    }
  });

  test('the actions that exist today need no more than they did as '
      'separate Functions', () {
    final byName = {for (final a in actions) a.name: a};
    final review = byName['review_demo_sign_in'];
    final delete = byName['delete_account'];

    expect(review?.scopes, <String>{'users.read', 'users.write'});
    expect(delete?.requiresUser, isTrue);
    expect(review?.requiresUser, isFalse);
  });

  test('the jobs action needs a signed-in caller (a worker identity)', () {
    final jobs = actions.singleWhere((a) => a.name == 'jobs');

    expect(jobs.requiresUser, isTrue);
  });
}
