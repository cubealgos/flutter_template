import 'dart:convert';

// The runtime's request is an untyped object (see `lib/main.dart`), so every
// member access on it is a deliberate dynamic call.
// ignore_for_file: avoid_dynamic_calls

/// The exact bytes of a runtime request's body.
///
/// The Dart runtime (open-runtimes, `RuntimeRequest`) keeps the body as
/// `bodyBinary` and derives `bodyText` as `utf8.decode(bodyBinary)` and
/// `bodyJson` as `jsonDecode(bodyText)`; `bodyJson` re-serialised is **not**
/// the sender's bytes (whitespace, key order, escapes), and a signature fails
/// on it. So this reads `bodyBinary` and falls back to the bytes of
/// `bodyText`, never to `bodyJson`.
List<int> rawBodyOf(dynamic req) {
  try {
    final binary = req.bodyBinary;
    if (binary is List) return List<int>.from(binary);
  } on Object {
    // A runtime without `bodyBinary`: use the text below.
  }
  try {
    final text = req.bodyText;
    if (text is String) return utf8.encode(text);
  } on Object {
    // No body at all.
  }

  return const <int>[];
}
