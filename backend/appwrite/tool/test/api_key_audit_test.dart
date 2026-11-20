import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:appwrite_tool/src/api_key_audit.dart';
import 'package:appwrite_tool/src/api_keys_gateway.dart';
import 'package:appwrite_tool/src/backend_env.dart';
import 'package:test/test.dart';

const _declared = <ApiKeySchema>[
  ApiKeySchema(
    id: 'deployer',
    name: 'deployer',
    purpose: 'deploys',
    scopes: <String>['functions.read', 'sites.write'],
  ),
];

void main() {
  test('matching keys produce no problems, in any scope order', () {
    expect(
      auditApiKeys(_declared, const <ExistingApiKey>[
        ExistingApiKey(
          id: 'deployer',
          name: 'deployer',
          scopes: <String>['sites.write', 'functions.read'],
        ),
      ]),
      isEmpty,
    );
  });

  test('missing, over-broad, under-scoped and undeclared keys are found', () {
    expect(
      auditApiKeys(_declared, const <ExistingApiKey>[]).single,
      contains('missing'),
    );
    final problems = auditApiKeys(_declared, const <ExistingApiKey>[
      ExistingApiKey(
        id: 'deployer',
        name: 'deployer',
        scopes: <String>['functions.read', 'users.write'],
      ),
      ExistingApiKey(id: 'old', name: 'old', scopes: <String>[]),
    ]);

    expect(
      problems.join('\n'),
      allOf(
        contains('undeclared scopes: users.write'),
        contains('lacks scopes: sites.write'),
        contains('undeclared key "old"'),
      ),
    );
  });

  test('the checklist names the key, its scopes and an env variable, '
      'and never a secret', () {
    final lines = apiKeyChecklist(
      _declared,
      projectId: 'proj',
      envFile: 'backend/appwrite/tool/.env.local',
      variableFor: BackendEnv.apiKeyVariable,
    ).join('\n');

    expect(lines, contains('--key-id deployer'));
    expect(lines, contains('--scopes "sites.write"'));
    expect(lines, contains('APPWRITE_API_KEY_DEPLOYER'));
    expect(lines, contains('appwrite-cli@26.1.0'));
  });
}
