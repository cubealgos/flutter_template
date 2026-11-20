import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tooling/src/cyclonedx_document.dart';
import 'package:tooling/src/sbom_component.dart';

import 'support/json_schema_validator.dart';

/// A syntactically valid (64 hex-looking chars), obviously-fake SHA-256 —
/// this test only cares that a hash renders correctly, never that it's
/// real.
const String _fakeSha256 =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

/// `test/fixtures/cyclonedx/{bom-1.6.schema.json,spdx.schema.json,
/// jsf-0.82.schema.json}` are CycloneDX's own official JSON Schema files
/// (Apache-2.0 — on the dependency-license allow list — from
/// `CycloneDX/specification`, tag `1.6`, fetched 2026-09-25), vendored
/// rather than fetched over the network from inside a test: a test suite
/// that needs network access is flaky by construction (CI's own network
/// path is otherwise only ever exercised by `licence-check`, deliberately
/// — see `.github/workflows/licence-check.yml`) and non-deterministic across
/// a spec revision nobody asked for. Pinned to exactly `1.6`, matching
/// `cycloneDxSpecVersion`; bump both together if the template ever
/// targets a newer CycloneDX release.
///
/// Validated with a small hand-rolled draft-07 subset
/// (`support/json_schema_validator.dart`) rather than a pub.dev
/// JSON-Schema package: the one real Dart validator, `json_schema`
/// (workiva), is Boost-Software-License-1.0 — not on this workspace's
/// dependency-license allow list (`core/tooling/tooling/lib/src/
/// licence_policy.dart`), and adding it just for a test would need its
/// own licence-policy exception for comparatively little payoff, since
/// `bom-1.6.schema.json` only actually exercises a small, checked-by-hand
/// subset of draft-07 in the first place (no `patternProperties`,
/// `allOf`, `if`/`then`, or the object form of `additionalProperties` —
/// see that validator's own doc comment).
Directory get _fixturesDir =>
    Directory(p.join(Directory.current.path, 'test', 'fixtures', 'cyclonedx'));

SchemaDocs _loadSchemaDocs() {
  Object? readJson(String name) =>
      jsonDecode(File(p.join(_fixturesDir.path, name)).readAsStringSync());

  return {
    'bom-1.6.schema.json': readJson('bom-1.6.schema.json'),
    'spdx.schema.json': readJson('spdx.schema.json'),
    'jsf-0.82.schema.json': readJson('jsf-0.82.schema.json'),
  };
}

void main() {
  final docs = _loadSchemaDocs();

  Map<String, Object> buildSample({
    List<SbomComponent> components = const [],
    String namespace = 'acme_notes',
  }) => buildCycloneDxBom((
    appName: 'app',
    appVersion: '1.0.0+1',
    components: components,
    timestamp: DateTime.utc(2026, 9, 25, 12),
    serialNumber: '3e671687-395b-41f5-a30f-a58921a69b79',
    toolVersion: '0.0.0',
    namespace: namespace,
  ));

  List<String> validate(Map<String, Object> document) => validateAgainstSchema(
    instance: document,
    docs: docs,
    rootDocument: 'bom-1.6.schema.json',
  );

  test('declares CycloneDX 1.6', () {
    final doc = buildSample();

    expect(doc['bomFormat'], 'CycloneDX');
    expect(doc['specVersion'], cycloneDxSpecVersion);
    expect(cycloneDxSpecVersion, '1.6');
  });

  test('serialNumber is a urn:uuid: RFC-4122 string', () {
    final doc = buildSample();

    expect(
      doc['serialNumber'],
      'urn:uuid:3e671687-395b-41f5-a30f-a58921a69b79',
    );
  });

  test('metadata carries the timestamp and the app as its own component', () {
    final doc = buildSample();
    // buildCycloneDxBom() always writes a 'metadata' object with its own
    // 'component' key — see cyclonedx_document.dart.
    // ignore: solid_lints/avoid_non_null_assertion
    final metadata = doc['metadata']! as Map;

    expect(metadata['timestamp'], '2026-09-25T12:00:00.000Z');
    // Same guarantee as metadata's own assertion above.
    // ignore: solid_lints/avoid_non_null_assertion
    final component = metadata['component']! as Map;
    expect(component['name'], 'app');
    expect(component['version'], '1.0.0+1');
  });

  test(
    'the app purl and tool name use the given namespace, not a fixed one',
    () {
      final doc = buildSample(namespace: 'someone_elses_app');
      // buildCycloneDxBom() always writes a 'metadata' object with its own
      // 'component' key — see cyclonedx_document.dart.
      // ignore: solid_lints/avoid_non_null_assertion
      final metadata = doc['metadata']! as Map;
      // Same guarantee as metadata's own assertion above.
      // ignore: solid_lints/avoid_non_null_assertion
      final component = metadata['component']! as Map;
      final tool = ((metadata['tools'] as Map)['components'] as List).single;

      expect(component['purl'], 'pkg:generic/someone_elses_app/app@1.0.0+1');
      expect((tool as Map)['name'], 'someone_elses_app tooling:sbom');
    },
  );

  test('an empty component list validates against the CycloneDX schema', () {
    expect(validate(buildSample()), isEmpty);
  });

  test('a hosted component with licence and hash validates', () {
    final doc = buildSample(
      components: const [
        SbomComponent(
          type: 'library',
          name: 'http',
          version: '1.2.3',
          purl: 'pkg:pub/http@1.2.3',
          sha256: _fakeSha256,
          licences: [SbomLicence.spdx('MIT')],
        ),
      ],
    );

    expect(validate(doc), isEmpty);
  });

  test('a first-party component with no licence validates', () {
    final doc = buildSample(
      components: const [
        SbomComponent(
          type: 'library',
          name: 'mvc',
          version: '0.0.0',
          purl: 'pkg:generic/example_app/mvc@0.0.0',
        ),
      ],
    );

    expect(validate(doc), isEmpty);
  });

  test('an SDK component with a framework type validates', () {
    final doc = buildSample(
      components: const [
        SbomComponent(
          type: 'framework',
          name: 'flutter',
          version: '3.47.5',
          purl: 'pkg:generic/flutter-sdk/flutter@3.47.5',
          licences: [SbomLicence.spdx('BSD-3-Clause')],
        ),
      ],
    );

    expect(validate(doc), isEmpty);
  });

  test('a free-text licence name also validates', () {
    final doc = buildSample(
      components: const [
        SbomComponent(
          type: 'library',
          name: 'oddball',
          version: '1.0.0',
          purl: 'pkg:pub/oddball@1.0.0',
          licences: [SbomLicence.freeText('Some Custom Licence')],
        ),
      ],
    );

    expect(validate(doc), isEmpty);
  });

  test('the validator itself catches a violation (missing "type")', () {
    final broken = <String, Object>{
      'bomFormat': 'CycloneDX',
      'specVersion': '1.6',
      'components': [
        {'name': 'oops'},
      ],
    };

    expect(validate(broken), isNotEmpty);
  });

  test('the validator rejects a wrong bomFormat', () {
    final doc = Map<String, Object>.from(buildSample())
      ..['bomFormat'] = 'NotCycloneDX';

    expect(validate(doc), isNotEmpty);
  });
}
