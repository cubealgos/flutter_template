import 'dart:io';

import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/forbidden_phrase.dart';
import 'package:tooling/src/yaml_field.dart';
import 'package:yaml/yaml.dart';

/// The parsed phrase file: the forbidden `phrases`, extra `sources` to
/// scan, and the keyed `exceptions`.
class PhraseConfig {
  /// Creates a config.
  const PhraseConfig({
    this.phrases = const <String>[],
    this.sources = const <String>[],
    this.exceptions = const <PhraseException>[],
  });

  /// The forbidden phrases, as written.
  final List<String> phrases;

  /// Extra files or directories (relative to the repo root) scanned in
  /// addition to the default copy sources.
  final List<String> sources;

  /// The keyed exceptions.
  final List<PhraseException> exceptions;
}

/// One keyed exception from `tool/phrase-check.yaml`: a deliberate
/// allowance for one phrase in one exact sentence — never for the phrase
/// everywhere. Keyed on (`phrase`, `sentence`) together, so editing the
/// sentence makes the entry stop matching and the gate re-refuses it.
class PhraseException {
  /// Creates an exception entry.
  const PhraseException({
    required this.phrase,
    required this.sentence,
    required this.reason,
    required this.date,
  });

  /// The forbidden phrase this exception covers, as written in `phrases:`.
  final String phrase;

  /// The exact sentence the phrase may appear in (whitespace-normalised).
  final String sentence;

  /// Why the sentence is acceptable, printed on every run.
  final String reason;

  /// The `YYYY-MM-DD` date the exception was granted.
  final String date;

  /// True if this exception covers [forPhrase] occurring in [inSentence].
  bool covers(String forPhrase, String inSentence) =>
      foldGerman(phrase) == foldGerman(forPhrase) &&
      normaliseWhitespace(sentence) == normaliseWhitespace(inSentence);

  @override
  String toString() => '"$phrase" in "$sentence" ($date): $reason';
}

final RegExp _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// Loads the phrase file at [path]. A missing file means nothing is
/// forbidden; a present, malformed file is a [CommandFailure].
PhraseConfig loadPhraseConfig(String path) {
  final file = File(path);
  if (!file.existsSync()) return const PhraseConfig();

  final Object? doc;
  try {
    doc = loadYaml(file.readAsStringSync());
  } on YamlException catch (e) {
    throw CommandFailure('$path is not valid YAML: $e');
  }
  if (doc == null) return const PhraseConfig();
  if (doc is! YamlMap) {
    throw CommandFailure('$path: the top level must be a map.');
  }

  return PhraseConfig(
    phrases: _stringList(doc, 'phrases', path),
    sources: _stringList(doc, 'sources', path),
    exceptions: [
      for (final raw in _list(doc, 'exceptions', path))
        _parseException(raw, path),
    ],
  );
}

List<Object?> _list(YamlMap doc, String key, String path) {
  final value = doc[key];
  if (value == null) return const <Object?>[];
  if (value is! YamlList) {
    throw CommandFailure("$path: '$key' must be a list.");
  }

  return value.toList();
}

List<String> _stringList(YamlMap doc, String key, String path) => [
  for (final item in _list(doc, key, path))
    if (item is String && item.trim().isNotEmpty)
      item
    else
      throw CommandFailure(
        "$path: every '$key' entry must be a non-empty string.",
      ),
];

PhraseException _parseException(Object? raw, String path) {
  if (raw is! YamlMap) {
    throw CommandFailure('$path: every exceptions entry must be a map.');
  }
  var ctx = (path: path, entryNoun: 'an entry', context: null as String?);
  final phrase = requireYamlField(raw, 'phrase', ctx);
  ctx = (path: path, entryNoun: ctx.entryNoun, context: phrase);
  final sentence = requireYamlField(raw, 'sentence', ctx);
  final reason = requireYamlField(raw, 'reason', ctx);
  final date = requireYamlField(raw, 'date', ctx);
  if (!_isoDate.hasMatch(date)) {
    throw CommandFailure(
      "$path: entry for '$phrase' has a 'date' that is not YYYY-MM-DD.",
    );
  }

  return PhraseException(
    phrase: phrase,
    sentence: sentence,
    reason: reason,
    date: date,
  );
}
