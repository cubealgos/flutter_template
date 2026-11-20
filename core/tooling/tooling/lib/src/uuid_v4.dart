// The byte indices and bit masks below are RFC 4122's own version-4 UUID
// layout (16 bytes; the version nibble lives in byte 6, the variant bits
// in byte 8; the canonical text form groups the 32 hex digits 8-4-4-4-12)
// — naming each one wouldn't make this any more readable, just longer.
// ignore_for_file: solid_lints/no_magic_number

import 'dart:math';

/// Generates a random RFC 4122 version-4 UUID, lower-case hyphenated
/// (`8-4-4-4-12` hex digits — the shape CycloneDX's `serialNumber` pattern
/// requires after its `urn:uuid:` prefix). No new dependency for this: a
/// UUIDv4 is 122 random bits plus 6 fixed version/variant bits, cheaply
/// generated from `dart:math`'s `Random.secure()` alone.
String generateUuidV4({Random? random}) {
  final rng = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10xx

  String hex(Iterable<int> slice) =>
      slice.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  return '${hex(bytes.sublist(0, 4))}-${hex(bytes.sublist(4, 6))}-'
      '${hex(bytes.sublist(6, 8))}-${hex(bytes.sublist(8, 10))}-'
      '${hex(bytes.sublist(10, 16))}';
}
