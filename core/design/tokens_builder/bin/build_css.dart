import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tokens_builder/src/css/build_css_tokens.dart';
import 'package:tokens_builder/src/css/css_emitter.dart';

/// Standard Unix `sysexits.h` "command line usage error" code — this
/// bin's own usage message uses it for a missing/malformed `--tokens`/
/// `--out` flag.
const int _usageErrorExitCode = 64;

/// Exit code for a runtime failure (e.g. the given `--tokens` directory
/// does not exist).
const int _runtimeErrorExitCode = 1;

/// `build_css`: reads every `<dir>/*.json` DTCG token source (the same
/// files `package:tokens_builder`'s `Builder` reads from `core/design/ui/tokens`
/// to generate `tokens.g.dart`) and writes one generated CSS custom-
/// properties file — `apps/website`'s single token source, committed and
/// never hand-edited.
///
/// A plain `dart run` bin rather than a `Builder` because build_runner
/// cannot read assets from outside the package that owns the build (a
/// builder in `apps/website` could not read `core/design/ui/tokens/*.json`,
/// and a builder in `core/design/tokens_builder` cannot write into
/// `apps/website/web/`) — see this package's own `README`/pubspec doc
/// comment. Wired into `melos run gen` as the `gen:website-tokens` step.
///
/// Usage: `dart run tokens_builder:build_css --tokens <dir> --out <file>`
/// (paths are resolved relative to [Directory.current], i.e. wherever the
/// command is invoked from — `melos run` always invokes from the repo
/// root).
Future<void> main(List<String> args) async {
  final tokensDir = _optionValue(args, '--tokens');
  final outFile = _optionValue(args, '--out');
  if (tokensDir == null || outFile == null) {
    stderr.writeln(
      'build_css: usage: dart run tokens_builder:build_css '
      '--tokens <dir> --out <file>',
    );
    exit(_usageErrorExitCode);
  }

  final dir = Directory(tokensDir);
  if (!dir.existsSync()) {
    stderr.writeln('build_css: token directory not found: $tokensDir');
    exit(_runtimeErrorExitCode);
  }

  final sources = <String, String>{};
  for (final entity in dir.listSync()) {
    if (entity is! File || p.extension(entity.path) != '.json') continue;
    sources[p.basename(entity.path)] = entity.readAsStringSync();
  }

  final result = buildCssTokensFromSources(sources);
  final css = emitCssSource(result);

  final out = File(outFile);
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(css);
  stdout.writeln(
    'build_css: wrote $outFile from ${sources.length} '
    'source file(s) in $tokensDir.',
  );
}

String? _optionValue(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) return null;

  return args[index + 1];
}
