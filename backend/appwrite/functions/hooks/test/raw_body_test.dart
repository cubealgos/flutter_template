// Test literals, `late` set-up fixtures and a group's long body are plain in a
// test and read worse as named constants or splits.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_late_keyword, solid_lints/prefer_match_file_name, solid_lints/number_of_parameters, solid_lints/function_lines_of_code, solid_lints/avoid_non_null_assertion

import 'dart:convert';

import 'package:hooks/src/raw_body.dart';
import 'package:paddle_billing/paddle_billing.dart';
import 'package:test/test.dart';

import 'support.dart';

/// The Dart runtime's request, as open-runtimes defines it
/// (`runtimes/dart/versions/latest/src/function_types.dart`): the body is kept
/// as bytes, and `bodyText`/`bodyJson` are derived from it on access.
class _RuntimeRequest {
  _RuntimeRequest(this.bodyBinary);

  final List<int> bodyBinary;

  String get bodyText => utf8.decode(bodyBinary);

  dynamic get bodyJson => jsonDecode(bodyText);
}

/// A runtime that only has the parsed JSON body (the hazard).
class _JsonOnly {
  dynamic get bodyJson => jsonDecode(utf8.decode(eventBody));
}

void main() {
  test('the handler gets the exact bytes: whitespace, an escape, a trailing '
      "newline - and the sender's signature verifies on them", () {
    final req = _RuntimeRequest(eventBody);
    final header = PaddleSignature.sign(
      rawBody: eventBody,
      secret: webhookSecret,
      timestamp: now,
    );

    final raw = rawBodyOf(req);

    expect(raw, eventBody);
    expect(
      PaddleSignature.verify(
        rawBody: raw,
        header: header,
        secret: webhookSecret,
        now: now,
      ),
      SignatureVerdict.valid,
    );
  });

  test("a re-serialised bodyJson is NOT the sender's bytes and fails the "
      'signature: why the hook never uses it', () {
    final header = PaddleSignature.sign(
      rawBody: eventBody,
      secret: webhookSecret,
      timestamp: now,
    );
    final reserialised = utf8.encode(jsonEncode(_JsonOnly().bodyJson));

    expect(reserialised, isNot(eventBody));
    expect(
      PaddleSignature.verify(
        rawBody: reserialised,
        header: header,
        secret: webhookSecret,
        now: now,
      ),
      SignatureVerdict.mismatch,
    );
  });

  test('falls back to the bytes of bodyText, and to nothing for no body', () {
    expect(rawBodyOf(_TextOnly()), utf8.encode('{ "a" : 1 }'));
    expect(rawBodyOf(Object()), isEmpty);
  });
}

class _TextOnly {
  String get bodyText => '{ "a" : 1 }';
}
