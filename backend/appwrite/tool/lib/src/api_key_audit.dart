import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/api_keys_gateway.dart';

/// Compares [declared] against [existing]: one line per discrepancy
/// (missing key, scope drift, undeclared key). Empty means they match.
List<String> auditApiKeys(
  List<ApiKeySchema> declared,
  List<ExistingApiKey> existing,
) {
  final problems = <String>[];
  final byId = {for (final k in existing) k.id: k};
  for (final key in declared) {
    final actual = byId[key.id];
    if (actual == null) {
      problems.add('missing key "${key.id}" (${key.purpose})');
      continue;
    }
    final want = key.scopes.toSet();
    final have = actual.scopes.toSet();
    final extra = have.difference(want).toList()..sort();
    final lacking = want.difference(have).toList()..sort();
    if (extra.isNotEmpty) {
      problems.add(
        'key "${key.id}" has undeclared scopes: ${extra.join(', ')}',
      );
    }
    if (lacking.isNotEmpty) {
      problems.add('key "${key.id}" lacks scopes: ${lacking.join(', ')}');
    }
  }
  final declaredIds = declared.map((k) => k.id).toSet();
  for (final key in existing) {
    if (!declaredIds.contains(key.id)) {
      problems.add('undeclared key "${key.id}" (${key.name}) exists');
    }
  }

  return problems;
}

/// The one-time manual creation checklist for [keys] in project
/// [projectId]: `dart_appwrite` 29.0.0 cannot create project keys, and
/// `appwrite-cli` 27+ dropped `project create-key`, so each is made through
/// `appwrite-cli@26.1.0` and its secret piped into the gitignored [envFile]
/// under the variable `BackendEnv.apiKeyVariable` names (never printed,
/// never an argument).
List<String> apiKeyChecklist(
  List<ApiKeySchema> keys, {
  required String projectId,
  required String envFile,
  required String Function(String keyId) variableFor,
}) {
  final lines = <String>[];
  for (final key in keys) {
    final scopeFlags = key.scopes.map((s) => '--scopes "$s"').join(' ');
    lines
      ..add('[ ] ${key.id}: ${key.purpose}')
      ..add(
        r'    ( set -o pipefail; umask 077; key="$(npx -y appwrite-cli@26.1.0 '
        'project create-key --project-id $projectId --key-id ${key.id} '
        '--name ${key.name} $scopeFlags --json --show-secrets | jq -r '
        r'.secret)" && [ ${#key} -gt 100 ] && '
        "printf '${variableFor(key.id)}=%s\\n' \"\$key\" >> $envFile )",
      );
  }

  return lines;
}
