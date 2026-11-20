import 'dart:convert';

/// Reads a dotted key path (e.g. `['signIn', 'title']`) out of [jsonContent]
/// — the already-read text of an `apps/app/lib/i18n/*.i18n.json` source
/// file (slang's own input format, plain nested JSON).
///
/// `WebSmokeCommand` uses this to read the real localized sign-in copy
/// ("Sign in" / "Anmelden") directly from `en.i18n.json`/`de.i18n.json`
/// rather than hand-duplicating it as a constant that could silently drift
/// from the app's actual strings. Pure (a string in, a string out — no
/// filesystem access), so it's exercised directly by
/// `web_smoke_i18n_test.dart` against fixture JSON text.
String readI18nString(String jsonContent, List<String> keyPath) {
  Object? node = jsonDecode(jsonContent);
  for (final key in keyPath) {
    node = _stepInto(node, key, keyPath);
  }
  if (node is! String) {
    throw FormatException(
      'i18n key "${keyPath.join('.')}" is not a string (got $node).',
    );
  }

  return node;
}

Object? _stepInto(Object? node, String key, List<String> keyPath) {
  if (node is! Map || !node.containsKey(key)) {
    throw FormatException(
      'i18n key "${keyPath.join('.')}" not found (missing "$key").',
    );
  }

  return node[key];
}
