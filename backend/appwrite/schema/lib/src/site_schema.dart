/// A deployable Appwrite Site: a prebuilt static web build uploaded as a
/// deployment (the tool never builds — see `backend/appwrite/README.md`).
class SiteSchema {
  /// Declares a Site named [name] with ID [id], deployed from the already
  /// built directory [buildOutputPath].
  const SiteSchema({
    required this.id,
    required this.name,
    required this.buildOutputPath,
    required this.buildCommand,
    this.fallbackFile = '',
  });

  /// The Site's ID.
  final String id;

  /// The Site's display name.
  final String name;

  /// Repo-relative directory holding the finished static build — what gets
  /// archived and uploaded. Must exist before deploying.
  final String buildOutputPath;

  /// The command, run from the repo root by the caller (never by the
  /// tool), that produces [buildOutputPath]. Documentation only: printed
  /// when the build output is missing.
  final String buildCommand;

  /// The file Appwrite serves for a path that matches no file (a
  /// single-page app's `index.html`); empty for a pre-rendered site, which
  /// ships its own `404.html`.
  final String fallbackFile;
}
