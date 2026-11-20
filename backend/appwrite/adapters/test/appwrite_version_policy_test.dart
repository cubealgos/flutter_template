import 'package:appwrite/appwrite.dart';
import 'package:appwrite_adapters/appwrite_adapters.dart';
import 'package:test/test.dart';

AppwriteVersionPolicy _policy(Future<Map<String, dynamic>?> Function() read) =>
    AppwriteVersionPolicy.withRowReader(read);

const int _serviceUnavailable = 503;

void main() {
  test('an absent row is allowed, not an error', () async {
    final result = await _policy(() async => null).check('1.0.0');

    expect(result.blocked, isFalse);
  });

  test('the provisioned default row (0.0.0) allows any app version', () async {
    final policy = _policy(
      () async => <String, dynamic>{'minSupportedVersion': '0.0.0'},
    );

    expect((await policy.check('1.0.0')).blocked, isFalse);
    expect((await policy.check('0.0.0')).blocked, isFalse);
  });

  test('blocks an app older than minSupportedVersion', () async {
    final policy = _policy(
      () async => <String, dynamic>{
        'minSupportedVersion': '2.0.0',
        'message': 'Please update',
      },
    );

    final result = await policy.check('1.9.9');

    expect(result.blocked, isTrue);
    expect(result.message, 'Please update');
  });

  test('fails open on a backend error', () async {
    final policy = _policy(
      () => throw AppwriteException('down', _serviceUnavailable),
    );

    expect((await policy.check('1.0.0')).blocked, isFalse);
  });

  test('fails open on a malformed value instead of throwing', () async {
    final policy = _policy(
      () async => <String, dynamic>{'minSupportedVersion': 5},
    );

    expect((await policy.check('1.0.0')).blocked, isFalse);
  });
}
