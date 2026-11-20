/// Lists the project's API keys (needs a key with `keys.read`).
abstract class ApiKeysGateway {
  /// Every key of the project.
  Future<List<ExistingApiKey>> listKeys();
}

/// A key as the project reports it.
class ExistingApiKey {
  /// Creates a snapshot.
  const ExistingApiKey({
    required this.id,
    required this.name,
    required this.scopes,
  });

  /// The key's ID.
  final String id;

  /// The key's name.
  final String name;

  /// Its scopes.
  final List<String> scopes;
}
