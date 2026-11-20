// Test literals, `late` set-up fixtures and a group's long body are plain in a
// test and read worse as named constants or splits.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_late_keyword, solid_lints/prefer_match_file_name, solid_lints/number_of_parameters, solid_lints/function_lines_of_code, solid_lints/avoid_non_null_assertion

import 'dart:convert';

import 'package:paddle_billing/paddle_billing.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 1, 12);
  const secret = 'pdl_ntfset_test_secret';
  final body = utf8.encode('{"event_id":"evt_1",  "data":{"a": 1}}\n');

  SignatureVerdict check(
    List<int> bytes, {
    String? header,
    DateTime? at,
    String key = secret,
  }) => PaddleSignature.verify(
    rawBody: bytes,
    header:
        header ??
        PaddleSignature.sign(rawBody: body, secret: secret, timestamp: now),
    secret: key,
    now: at ?? now,
  );

  test('a body signed with the secret verifies, byte for byte', () {
    expect(check(body), SignatureVerdict.valid);
  });

  test('matches the documented scheme: HMAC-SHA256 of "<ts>:<raw body>"', () {
    // Computed independently:
    //   printf '1788264000:{"a":1}' | openssl dgst -sha256 -hmac key
    const expected =
        '49ec41a77edc25acf07644b7389c16226523f37d35b0a3fbe91f89adbdca3c4e';
    final header = PaddleSignature.sign(
      rawBody: utf8.encode('{"a":1}'),
      secret: 'key',
      timestamp: DateTime.utc(2026, 9, 1, 12),
    );

    expect(header, 'ts=1788264000;h1=$expected');
  });

  test('a forged signature (wrong secret) is a mismatch', () {
    expect(check(body, key: 'another-secret'), SignatureVerdict.mismatch);
  });

  test(
    'a body that changed by one byte, or was re-serialised, is a mismatch',
    () {
      final reserialised = utf8.encode(
        jsonEncode(jsonDecode(utf8.decode(body))),
      );

      expect(check(reserialised), SignatureVerdict.mismatch);
      expect(check(<int>[...body, 0x20]), SignatureVerdict.mismatch);
    },
  );

  test('an old timestamp is stale, a missing or garbled header malformed', () {
    expect(
      check(body, at: now.add(const Duration(minutes: 5))),
      SignatureVerdict.stale,
    );
    expect(check(body, header: ''), SignatureVerdict.malformed);
    expect(check(body, header: 'nonsense'), SignatureVerdict.malformed);
    expect(check(body, header: 'ts=abc;h1=00'), SignatureVerdict.malformed);
    expect(
      PaddleSignature.verify(
        rawBody: body,
        header: null,
        secret: secret,
        now: now,
      ),
      SignatureVerdict.malformed,
    );
  });

  test('during a secret rotation any of several h1 values may match', () {
    final good = PaddleSignature.sign(
      rawBody: body,
      secret: secret,
      timestamp: now,
    );
    final ts = good.split(';').first;
    final h1 = good.split('h1=').last;

    expect(
      check(body, header: '$ts;h1=${'0' * 64};h1=$h1'),
      SignatureVerdict.valid,
    );
  });

  test('a signature for another timestamp does not verify', () {
    final other = PaddleSignature.sign(
      rawBody: body,
      secret: secret,
      timestamp: now.add(const Duration(seconds: 3)),
    );
    final ts = now.millisecondsSinceEpoch ~/ 1000;
    final forged = 'ts=$ts;h1=${other.split('h1=').last}';

    expect(check(body, header: forged), SignatureVerdict.mismatch);
  });
}
