/// A narrowly scoped server API key one component of the tooling uses.
///
/// Declared here, not created by code: `dart_appwrite` 29.0.0's
/// project-level `Project` service can list, get, update and delete keys
/// but has no `createKey` (only `createEphemeralKey`, at most one hour),
/// so a key is created once by hand and audited afterwards — see
/// `backend/appwrite/README.md` "Scoped API keys".
class ApiKeySchema {
  /// Declares a key with ID [id], display [name], granting [scopes], for
  /// [purpose].
  const ApiKeySchema({
    required this.id,
    required this.name,
    required this.scopes,
    required this.purpose,
  });

  /// The key's ID (also used as its `--key-id` when created).
  final String id;

  /// The key's display name.
  final String name;

  /// The scopes the key is allowed, exactly. No more, no fewer.
  final List<String> scopes;

  /// Which command or component uses this key.
  final String purpose;
}
