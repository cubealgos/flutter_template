import 'package:appwrite_tool/src/api_keys_gateway.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

/// [ApiKeysGateway] backed by `Project.listKeys` (the secrets in the
/// response are never read).
class DartAppwriteApiKeysGateway implements ApiKeysGateway {
  /// Creates a gateway over [client].
  DartAppwriteApiKeysGateway(Client client) : _project = Project(client);

  final Project _project;

  @override
  Future<List<ExistingApiKey>> listKeys() async {
    final list = await _project.listKeys();

    return <ExistingApiKey>[
      for (final key in list.keys)
        ExistingApiKey(id: key.$id, name: key.name, scopes: key.scopes),
    ];
  }
}
