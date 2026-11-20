import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tooling/src/pub_dev_licence_client.dart';

/// The HTTP status a fake pub.dev score response carries.
const int fakePubDevStatusOk = 200;

/// A [PubDevLicenceClient] that never touches the network: answers
/// `GET .../api/packages/<name>/score` from [tagsByName] (`'unknown'` for
/// any name not in it, matching a real pub.dev "nothing detected"
/// response), caching to [cacheDir].
///
/// Shared by `licence_check_command_test.dart` and `sbom_command_test.dart`
/// — solid_lints' `avoid_duplicate_code` flagged the two tests' own,
/// separately hand-written versions of this as an exact structural
/// duplicate once both existed.
PubDevLicenceClient fakePubDevLicenceClient({
  required String cacheDir,
  required Map<String, List<String>> tagsByName,
}) {
  return PubDevLicenceClient(
    cacheDir: cacheDir,
    httpClient: MockClient((request) async {
      final name = request
          .url
          .pathSegments[2]; // /api/packages/<name>/versions/<v>/score
      final tags = tagsByName[name] ?? const ['unknown'];

      return http.Response(
        jsonEncode({'tags': tags.map((t) => 'license:$t').toList()}),
        fakePubDevStatusOk,
      );
    }),
  );
}
