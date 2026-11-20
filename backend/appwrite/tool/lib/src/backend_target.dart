/// Which Appwrite project a command runs against.
enum BackendTarget {
  /// The dev project, configured by `.env.local`.
  dev('.env.local'),

  /// The production project, configured by `.env.production.local` — only
  /// ever reached with an explicit confirmation, see
  /// `ProductionNotConfirmedException`.
  production('.env.production.local');

  BackendTarget(this.envFileName);

  /// The gitignored env file holding this target's endpoint, project ID and
  /// API key.
  final String envFileName;
}

/// The command-line flag that confirms a command may touch the production
/// project. Without it every command refuses, even if
/// `.env.production.local` exists.
const String productionFlag = '--production';
