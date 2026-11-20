@Tags(['end_to_end'])
library;

import 'dart:io';

import 'package:test/test.dart';

/// One real `dart run build_runner build` against a throwaway fixture
/// package that depends on `tokens_builder` by path — proves the builder
/// wires up correctly through `build.yaml`'s `auto_apply: dependents`, not
/// just through the pure `buildTokensFromSources` function the other tests
/// exercise directly. `package:build_test`'s mock resolver is known to
/// overflow the stack on `GeneratorForAnnotation`, which is why this is a real
/// subprocess rather than `package:build_test`'s mock resolver — moot here
/// (this builder never resolves Dart source, only JSON assets), but the
/// real run is cheap insurance regardless.
void main() {
  test('build_runner generates tokens.g.dart in a fixture package', () async {
    final tokensBuilderPath = Directory.current.absolute.path;
    final fixture = await Directory.systemTemp.createTemp(
      'tokens_builder_e2e_',
    );
    addTearDown(() => fixture.delete(recursive: true));

    Directory('${fixture.path}/tokens').createSync();
    Directory('${fixture.path}/lib/src').createSync(recursive: true);
    File('${fixture.path}/tokens/dimension.json').writeAsStringSync(
      r'{"space": {"4": {"$type": "dimension", "$value": "16px"}}}',
    );
    File('${fixture.path}/tokens/color.light.json').writeAsStringSync(
      r'{"color": {"a": {"$type": "color", "$value": "#ffffff"}}}',
    );
    File('${fixture.path}/tokens/color.dark.json').writeAsStringSync(
      r'{"color": {"a": {"$type": "color", "$value": "#000000"}}}',
    );
    File('${fixture.path}/pubspec.yaml').writeAsStringSync('''
name: tokens_builder_e2e_fixture
publish_to: none
environment:
  sdk: ^3.13.0
dev_dependencies:
  build_runner: 2.15.1
  tokens_builder:
    path: $tokensBuilderPath
''');
    // build_runner's default source visibility excludes `tokens/**` — see
    // core/design/ui/build.yaml for the full explanation; this fixture needs
    // the same override.
    File('${fixture.path}/build.yaml').writeAsStringSync(r'''
targets:
  $default:
    sources:
      include:
        - lib/**
        - tokens/**
        - $package$
''');

    final pubGet = await Process.run('dart', [
      'pub',
      'get',
      '--offline',
    ], workingDirectory: fixture.path);
    expect(
      pubGet.exitCode,
      0,
      reason: pubGet.stdout.toString() + pubGet.stderr.toString(),
    );

    final build = await Process.run('dart', [
      'run',
      'build_runner',
      'build',
      '--delete-conflicting-outputs',
    ], workingDirectory: fixture.path);
    expect(
      build.exitCode,
      0,
      reason: build.stdout.toString() + build.stderr.toString(),
    );

    final generated = File('${fixture.path}/lib/src/tokens.g.dart');
    expect(generated.existsSync(), isTrue);
    final source = generated.readAsStringSync();
    expect(source, contains("SpaceToken('space.4')"));
    expect(source, contains('space4: 16.0'));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
