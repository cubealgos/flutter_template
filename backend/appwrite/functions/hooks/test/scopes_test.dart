import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:hooks/src/registry.dart';
import 'package:test/test.dart';

void main() {
  test("the hooks Function's declared scopes are exactly the ones its hooks "
      'need', () {
    final declared = templateSchema.functions
        .singleWhere((function) => function.id == 'hooks')
        .scopes
        .toSet();

    expect(declared.difference(requiredScopes), isEmpty);
    expect(requiredScopes.difference(declared), isEmpty);
  });

  test('every hook has a unique path starting with a slash', () {
    final paths = hooks.map((hook) => hook.path).toList();

    expect(paths.toSet(), hasLength(paths.length));
    for (final path in paths) {
      expect(path, startsWith('/'));
    }
  });
}
