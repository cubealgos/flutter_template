import 'dart:io';

import 'package:appwrite_tool/src/backend_target.dart';
import 'package:appwrite_tool/src/mail_settings.dart';
import 'package:appwrite_tool/src/repo_root.dart';
import 'package:path/path.dart' as p;

/// The minimum length a quoted `.env` value can have: the two quote
/// characters themselves, with nothing between them (`""`).
const int _minimumQuotedValueLength = 2;

/// The configuration `bin/provision.dart` and `bin/deploy.dart` need to talk
/// to an Appwrite instance: endpoint, project and a server API key.
///
/// Read from environment variables (`APPWRITE_ENDPOINT`,
/// `APPWRITE_PROJECT_ID`, `APPWRITE_API_KEY`) or, if unset, from a
/// gitignored `backend/appwrite/tool/.env.local` file (see `backend/appwrite/tool/.env.example`) —
/// **never from command-line arguments**, so the API key never lands in
/// shell history or a process list.
class BackendEnv {
  /// Creates a config value directly (mainly for tests).
  const BackendEnv({
    required this.endpoint,
    required this.projectId,
    required this.apiKey,
    this.mail = const <String, String>{},
  });

  /// Loads config from [environment] (defaults to [Platform.environment]),
  /// falling back to a `.env.local` file for any key [environment] doesn't
  /// set. [dotEnvFile] overrides file discovery (mainly for tests); by
  /// default this looks for `.env.local` in the current directory, then in
  /// `backend/appwrite/tool/.env.local` (both relative to the current directory, so it
  /// works whether a command was run from the repo root or from inside
  /// `backend/`), then finally in the *shared* `backend/appwrite/tool/.env.local` every
  /// worktree of this clone resolves to (`findSharedBackendDir` — see
  /// `repo_root.dart`), so one Cloud project's key needn't be copied into
  /// every worktree.
  ///
  /// [workingDirectory] replaces "the current directory" in that search
  /// (defaults to [Directory.current]). Tests pass it instead of setting the
  /// process-wide current directory, which races with other test files
  /// loading in parallel isolates of the same process.
  ///
  /// Throws a [MissingBackendConfigException] naming the missing key if any
  /// of the three values isn't set anywhere.
  factory BackendEnv.load({
    Map<String, String>? environment,
    File? dotEnvFile,
    Directory? workingDirectory,
    String? keyId,
    BackendTarget target = BackendTarget.dev,
    bool allowProduction = false,
  }) {
    final isProduction = target == BackendTarget.production;
    if (isProduction && !allowProduction) {
      throw const ProductionNotConfirmedException();
    }
    final dir = workingDirectory ?? Directory.current;
    // Production reads only its own file, never process environment
    // variables: a stray dev `APPWRITE_*` variable must not be able to
    // redirect (or silently override) a production run.
    final env = isProduction
        ? const <String, String>{}
        : (environment ?? Platform.environment);
    final fileValues = _parseDotEnv(
      dotEnvFile ?? _findDotEnvFile(dir, target.envFileName),
    );

    String require(String key) {
      final value = env[key] ?? fileValues[key];
      if (value == null || value.isEmpty) {
        throw MissingBackendConfigException(key);
      }

      return value;
    }

    final loaded = BackendEnv(
      endpoint: require('APPWRITE_ENDPOINT'),
      projectId: require('APPWRITE_PROJECT_ID'),
      apiKey: _requireApiKey(require, keyId, env, fileValues),
      mail: _mailValues(env, fileValues),
    );
    if (!isProduction && dotEnvFile == null) {
      _refuseIfProductionProject(dir, loaded.projectId);
    }

    return loaded;
  }

  /// The `MAIL_*` variables that are set (see `mailEnvKeys`): the SMTP
  /// settings, read like the rest and never from an argument.
  /// Empty when mail is not configured.
  final Map<String, String> mail;

  /// The Appwrite REST endpoint, e.g. `https://fra.cloud.appwrite.io/v1`.
  final String endpoint;

  /// The Appwrite project ID.
  final String projectId;

  /// A server API key with the scopes `provision.dart`/`deploy.dart` need
  /// (databases, functions, storage, users — see `backend/appwrite/README.md`).
  final String apiKey;

  /// A dev run whose project ID is the production project's (e.g. a
  /// production ID exported into the shell) is a production run in
  /// disguise: refuse it too.
  static void _refuseIfProductionProject(Directory dir, String projectId) {
    final productionId = _parseDotEnv(
      _findDotEnvFile(dir, BackendTarget.production.envFileName),
    )['APPWRITE_PROJECT_ID'];
    if (productionId != null && productionId == projectId) {
      throw const ProductionNotConfirmedException(viaDevConfig: true);
    }
  }

  /// The `MAIL_*` variables set in [env] or [fileValues], non-empty only.
  static Map<String, String> _mailValues(
    Map<String, String> env,
    Map<String, String> fileValues,
  ) => <String, String>{
    for (final key in mailEnvKeys)
      if (env[key] ?? fileValues[key] case final value? when value.isNotEmpty)
        key: value,
  };

  /// The environment variable holding the scoped API key [keyId] (an
  /// `ApiKeySchema.id`): `deployer` -> `APPWRITE_API_KEY_DEPLOYER`,
  /// `review-demo-seeder` -> `APPWRITE_API_KEY_REVIEW_DEMO_SEEDER`.
  static String apiKeyVariable(String keyId) =>
      'APPWRITE_API_KEY_${keyId.toUpperCase().replaceAll('-', '_')}';

  /// The scoped key for [keyId] when configured, else the single
  /// `APPWRITE_API_KEY` (the earlier single-key setup keeps working).
  static String _requireApiKey(
    String Function(String key) require,
    String? keyId,
    Map<String, String> env,
    Map<String, String> fileValues,
  ) {
    if (keyId != null) {
      final scoped = apiKeyVariable(keyId);
      final value = env[scoped] ?? fileValues[scoped];
      if (value != null && value.isNotEmpty) return value;
    }

    return require('APPWRITE_API_KEY');
  }

  static File? _findDotEnvFile(Directory workingDirectory, String fileName) {
    for (final candidate in <String>[
      fileName,
      'backend/appwrite/tool/$fileName',
    ]) {
      final file = File(p.join(workingDirectory.path, candidate));
      if (file.existsSync()) return file;
    }

    final sharedDir = findSharedBackendDir(workingDirectory);
    if (sharedDir == null) return null;
    final sharedFile = File(
      p.join(sharedDir.path, 'appwrite', 'tool', fileName),
    );

    return sharedFile.existsSync() ? sharedFile : null;
  }

  static Map<String, String> _parseDotEnv(File? file) {
    if (file == null || !file.existsSync()) return <String, String>{};

    final values = <String, String>{};
    for (final rawLine in file.readAsLinesSync()) {
      final entry = _parseDotEnvLine(rawLine);
      if (entry != null) values[entry.key] = entry.value;
    }

    return values;
  }

  /// Parses one `.env` line into a key/value pair, or returns null for a
  /// blank line, a comment, or a line without an `=`.
  static MapEntry<String, String>? _parseDotEnvLine(String rawLine) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) return null;
    final separator = line.indexOf('=');
    if (separator == -1) return null;

    final key = line.substring(0, separator).trim();
    final rawValue = line.substring(separator + 1).trim();
    final value = _stripSurroundingQuotes(rawValue);

    return MapEntry<String, String>(key, value);
  }

  static String _stripSurroundingQuotes(String value) {
    if (value.length < _minimumQuotedValueLength) return value;
    final isDoubleQuoted = value.startsWith('"') && value.endsWith('"');
    final isSingleQuoted = value.startsWith("'") && value.endsWith("'");
    if (!isDoubleQuoted && !isSingleQuoted) return value;

    return value.substring(1, value.length - 1);
  }
}

/// Thrown by [BackendEnv.load] when a required config value is set nowhere
/// — not an environment variable and not in the `.env.local` file.
///
/// A dedicated exception type (rather than [StateError]) so callers can
/// catch it specifically without catching [Error]s as control flow.
class MissingBackendConfigException implements Exception {
  /// Creates an exception naming the missing [key].
  const MissingBackendConfigException(this.key);

  /// The missing config key, e.g. `APPWRITE_API_KEY`.
  final String key;

  @override
  String toString() =>
      'Missing required backend config "$key" - set it as an environment '
      'variable or in backend/appwrite/tool/.env.local (see backend/appwrite/tool/.env.example).';
}

/// Thrown by [BackendEnv.load] when a command would run against the
/// production project without the explicit [productionFlag].
class ProductionNotConfirmedException implements Exception {
  /// Creates the exception. [viaDevConfig] is true when the *dev*
  /// configuration itself resolved to the production project.
  const ProductionNotConfirmedException({this.viaDevConfig = false});

  /// Whether the dev configuration pointed at the production project.
  final bool viaDevConfig;

  @override
  String toString() => viaDevConfig
      ? 'Refusing: the dev configuration (.env.local or environment) points '
            'at the production project. Fix it, or pass $productionFlag to '
            'say so on purpose.'
      : 'Refusing to touch the production project without $productionFlag. '
            'Pass it explicitly (see docs/releasing.md "Deploying").';
}
