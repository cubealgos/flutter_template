import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:tokens_builder/src/emit/dart_emitter.dart';
import 'package:tokens_builder/src/model/build_tokens.dart';

/// Creates the [Builder] `build.yaml` wires up as `tokens_builder`.
///
/// Ignores the [BuilderOptions] argument — this builder has no
/// configuration surface, but a `BuilderFactory` must still accept one.
Builder tokensBuilder(BuilderOptions _) => const TokensBuilder();

/// Turns every `tokens/*.json` DTCG source file in the current package into
/// one generated `lib/src/tokens.g.dart` — see [buildTokensFromSources] for
/// the pure transform this wraps.
class TokensBuilder implements Builder {
  /// Creates the tokens builder.
  const TokensBuilder();

  @override
  Map<String, List<String>> get buildExtensions => const {
    r'$package$': ['lib/src/tokens.g.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final sources = <String, String>{};
    await for (final id in buildStep.findAssets(Glob('tokens/*.json'))) {
      sources[p.basename(id.path)] = await buildStep.readAsString(id);
    }
    final result = buildTokensFromSources(sources);
    final output = AssetId(buildStep.inputId.package, 'lib/src/tokens.g.dart');
    await buildStep.writeAsString(output, emitTokensSource(result));
  }
}
