import 'package:tooling/src/sbom_component.dart';

/// The CycloneDX specification version every document [buildCycloneDxBom]
/// emits declares itself as (see `bomFormat`/`specVersion` in the vendored
/// schema, `test/fixtures/cyclonedx/bom-1.6.schema.json`).
const String cycloneDxSpecVersion = '1.6';

/// Everything [buildCycloneDxBom] needs, grouped into a record (rather
/// than six loose parameters — see root `analysis_options.yaml`'s
/// `number_of_parameters` threshold) so every field stays named and
/// self-describing at the call site.
///
/// `timestamp` and `serialNumber` are both required, deliberately never
/// defaulted here — `sbom_command.dart` is the one place that picks a
/// real clock reading and generates a real random serial number, so a
/// test calling [buildCycloneDxBom] directly gets fully deterministic
/// output (see `sbom_document_test.dart`) without needing to fake either
/// one.
typedef CycloneDxBomInput = ({
  String appName,
  String appVersion,
  List<SbomComponent> components,
  DateTime timestamp,
  String serialNumber,
  String toolVersion,
  String namespace,
});

/// Builds a CycloneDX [cycloneDxSpecVersion] JSON document (as a plain
/// `Map`, ready for `jsonEncode`) describing [input]'s app and its
/// resolved dependency closure. `input.namespace` (see
/// `workspace_purl_namespace.dart`) is the `pkg:generic/<namespace>/...`
/// segment used for the app's own metadata component's purl and for the
/// SBOM-generating tool's own display name below — both describe *this
/// workspace*, so both use its own name, not a fixed one.
Map<String, Object> buildCycloneDxBom(CycloneDxBomInput input) {
  final appPurl =
      'pkg:generic/${input.namespace}/${input.appName}@${input.appVersion}';

  return {
    'bomFormat': 'CycloneDX',
    'specVersion': cycloneDxSpecVersion,
    'serialNumber': 'urn:uuid:${input.serialNumber}',
    'version': 1,
    'metadata': {
      'timestamp': input.timestamp.toUtc().toIso8601String(),
      'tools': {
        'components': [
          {
            'type': 'application',
            'name': '${input.namespace} tooling:sbom',
            'version': input.toolVersion,
          },
        ],
      },
      'component': {
        'type': 'application',
        'bom-ref': appPurl,
        'name': input.appName,
        'version': input.appVersion,
        'purl': appPurl,
      },
    },
    'components': [
      for (final component in input.components) component.toJson(),
    ],
  };
}
