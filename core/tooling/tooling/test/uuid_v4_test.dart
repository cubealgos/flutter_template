import 'dart:math';

import 'package:test/test.dart';
import 'package:tooling/src/uuid_v4.dart';

void main() {
  final pattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  test('generates a version-4, variant-10xx UUID in lower-case hex', () {
    expect(generateUuidV4(), matches(pattern));
  });

  test('is deterministic when given a seeded Random', () {
    final a = generateUuidV4(random: Random(1));
    final b = generateUuidV4(random: Random(1));

    expect(a, b);
  });

  test('two default (unseeded) calls differ', () {
    expect(generateUuidV4(), isNot(generateUuidV4()));
  });
}
