import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/forbidden_phrase.dart';
import 'package:tooling/src/phrase_config.dart';

/// The copy sources `phrase_check` always scans, relative to the repo root:
/// the `apps/app` i18n JSON and the website's copy (its i18n strings, pages
/// and components — string literals only). A default that does not exist
/// (a clone that dropped the website) is skipped; a path listed in the
/// phrase file's `sources:` that does not exist is an error.
const List<String> defaultPhraseSources = <String>[
  'apps/app/lib/i18n',
  'apps/website/lib/src/i18n',
  'apps/website/lib/src/pages',
  'apps/website/lib/src/components',
];

/// Capture groups of `_dartLiteral`.
const int _singleQuoted = 1;
const int _doubleQuoted = 2;

/// File extensions scanned inside a source directory.
const Set<String> _scannedExtensions = <String>{
  '.json',
  '.dart',
  '.html',
  '.md',
  '.txt',
};

/// Scans the copy sources for the forbidden phrases in
/// `tool/phrase-check.yaml` and fails (exit 1) on any occurrence that no
/// keyed exception covers. Prints every active exception on every run.
class PhraseCheckCommand {
  /// Creates a command rooted at [repoRoot], reading [phrasesPath]
  /// (relative to [repoRoot], default `tool/phrase-check.yaml`) and scanning
  /// [defaultSources] plus the file's own `sources:`.
  PhraseCheckCommand({
    required this.repoRoot,
    this.phrasesPath = 'tool/phrase-check.yaml',
    this.defaultSources = defaultPhraseSources,
  });

  /// The repo root every relative path is resolved against.
  final String repoRoot;

  /// The phrase file, relative to [repoRoot].
  final String phrasesPath;

  /// The always-scanned sources, relative to [repoRoot].
  final List<String> defaultSources;

  /// A single- or double-quoted Dart string literal on one line.
  static final RegExp _dartLiteral = RegExp(
    r"'((?:[^'\\]|\\.)*)'|"
    r'"((?:[^"\\]|\\.)*)"',
  );

  /// Runs the check and returns the exit code (`0` clean, `1` on a
  /// forbidden phrase or a malformed phrase file).
  int run({
    void Function(String) out = _defaultOut,
    void Function(String) err = _defaultErr,
  }) {
    final PhraseConfig config;
    final List<PhraseHit> hits;
    try {
      config = loadPhraseConfig(p.join(repoRoot, phrasesPath));
      hits = _scan(config);
    } on CommandFailure catch (e) {
      err('phrase_check: ${e.message}');

      return e.exitCode;
    }

    final unexcused = [
      for (final hit in hits)
        if (!config.exceptions.any((e) => e.covers(hit.phrase, hit.sentence)))
          hit,
    ];
    out(
      'phrase_check: ${config.phrases.length} forbidden phrase(s), '
      '${hits.length} occurrence(s) found — '
      '${hits.length - unexcused.length} excepted, '
      '${unexcused.length} forbidden.',
    );
    out('');
    _reportExceptions(config.exceptions, hits, out);
    if (unexcused.isEmpty) return 0;

    out('');
    out('Forbidden phrases:');
    for (final hit in unexcused) {
      out('  - $hit');
    }
    err(
      'phrase_check: ${unexcused.length} forbidden phrase occurrence(s). '
      'Reword the sentence, or record a keyed exception in $phrasesPath.',
    );

    return 1;
  }

  void _reportExceptions(
    List<PhraseException> exceptions,
    List<PhraseHit> hits,
    void Function(String) out,
  ) {
    out(
      exceptions.isEmpty
          ? 'Active exceptions: none.'
          : 'Active exceptions (${exceptions.length}):',
    );
    for (final exception in exceptions) {
      final used = hits.any((h) => exception.covers(h.phrase, h.sentence));
      out('  - $exception${used ? '' : ' [matches nothing now]'}');
    }
  }

  List<PhraseHit> _scan(PhraseConfig config) {
    // Resolved first so a mistyped `sources:` entry fails even while the
    // phrase list is still empty.
    final files = _files(config);
    final phrases = [for (final text in config.phrases) ForbiddenPhrase(text)];
    final hits = <PhraseHit>[];
    if (phrases.isEmpty) return hits;
    for (final file in files) {
      final relative = p.relative(file.path, from: repoRoot);
      for (final unit in _units(file, relative)) {
        for (final sentence in splitSentences(unit.text)) {
          for (final phrase in phrases) {
            if (!phrase.occursIn(sentence)) continue;
            hits.add(
              PhraseHit(
                file: relative,
                location: unit.location,
                phrase: phrase.text,
                sentence: sentence,
              ),
            );
          }
        }
      }
    }

    return hits;
  }

  /// Every file to scan, in a deterministic order, each once.
  List<File> _files(PhraseConfig config) {
    final files = <String, File>{};
    for (final source in defaultSources) {
      _addSource(files, source, mustExist: false);
    }
    for (final source in config.sources) {
      _addSource(files, source, mustExist: true);
    }

    return files.values.toList()..sort((a, b) => a.path.compareTo(b.path));
  }

  void _addSource(
    Map<String, File> files,
    String source, {
    required bool mustExist,
  }) {
    final path = p.join(repoRoot, source);
    if (FileSystemEntity.isDirectorySync(path)) {
      final found = Directory(path)
          .listSync(recursive: true)
          .whereType<File>()
          .where(_isScannable);
      for (final file in found) {
        files[file.path] = file;
      }
    } else if (File(path).existsSync()) {
      files[path] = File(path);
    } else if (mustExist) {
      throw CommandFailure("$phrasesPath: source '$source' does not exist.");
    }
  }

  bool _isScannable(File file) {
    final name = p.basename(file.path);
    final generated =
        name.endsWith('.g.dart') || name.endsWith('.freezed.dart');

    return !generated && _scannedExtensions.contains(p.extension(name));
  }

  /// The pieces of copy in [file]: every JSON string value (not keys),
  /// every Dart string literal, or every line of any other file.
  Iterable<({String location, String text})> _units(
    File file,
    String relative,
  ) {
    final content = file.readAsStringSync();
    switch (p.extension(file.path)) {
      case '.json':
        final Object? decoded;
        try {
          decoded = jsonDecode(content);
        } on FormatException catch (e) {
          throw CommandFailure('$relative is not valid JSON: ${e.message}');
        }

        return _jsonStrings(decoded, '');
      case '.dart':
        return _dartStrings(content);
      default:
        return _lines(content);
    }
  }

  Iterable<({String location, String text})> _jsonStrings(
    Object? node,
    String path,
  ) sync* {
    if (node is String) {
      yield (location: path.isEmpty ? r'$' : path, text: node);
    } else if (node is Map) {
      yield* _jsonChildren({
        for (final e in node.entries) '${e.key}': e.value,
      }, path);
    } else if (node is List) {
      yield* _jsonChildren({
        for (var i = 0; i < node.length; i++) '[$i]': node[i],
      }, path);
    }
  }

  Iterable<({String location, String text})> _jsonChildren(
    Map<String, Object?> children,
    String path,
  ) sync* {
    for (final entry in children.entries) {
      final isIndex = entry.key.startsWith('[');
      final separator = path.isEmpty || isIndex ? '' : '.';
      yield* _jsonStrings(entry.value, '$path$separator${entry.key}');
    }
  }

  Iterable<({String location, String text})> _dartStrings(
    String content,
  ) sync* {
    final lines = const LineSplitter().convert(content);
    for (var i = 0; i < lines.length; i++) {
      for (final match in _dartLiteral.allMatches(lines[i])) {
        final text =
            (match.group(_singleQuoted) ?? match.group(_doubleQuoted) ?? '')
                .replaceAll(r"\'", "'")
                .replaceAll(r'\"', '"');
        yield (location: 'line ${i + 1}', text: text);
      }
    }
  }

  Iterable<({String location, String text})> _lines(String content) sync* {
    final lines = const LineSplitter().convert(content);
    for (var i = 0; i < lines.length; i++) {
      yield (location: 'line ${i + 1}', text: lines[i]);
    }
  }

  static void _defaultOut(String message) => stdout.writeln(message);
  static void _defaultErr(String message) => stderr.writeln(message);
}

/// One forbidden phrase found in one sentence.
class PhraseHit {
  /// Creates a hit.
  const PhraseHit({
    required this.file,
    required this.location,
    required this.phrase,
    required this.sentence,
  });

  /// The scanned file, relative to the repo root.
  final String file;

  /// Where in [file]: a JSON key path, or a line number.
  final String location;

  /// The forbidden phrase, as written in the phrase file.
  final String phrase;

  /// The whitespace-normalised sentence containing it.
  final String sentence;

  @override
  String toString() => '$file ($location): "$phrase" in "$sentence"';
}
