import 'dart:io';

/// Remembers which commits had a successful dry run, so a real promotion
/// can refuse to run without one.
abstract class DryRunLedger {
  /// Records a successful dry run for [sha].
  void record(String sha);

  /// Whether [sha] had a successful dry run.
  bool has(String sha);
}

/// A [DryRunLedger] of marker files in [directory] (created on demand).
class FileDryRunLedger implements DryRunLedger {
  /// Creates a ledger; [scope] (e.g. the production project ID) keeps
  /// projects apart.
  FileDryRunLedger(this.directory, {required this.scope});

  /// Where marker files live.
  final Directory directory;

  /// Namespaces markers per project.
  final String scope;

  File _file(String sha) => File('${directory.path}/$scope-$sha');

  @override
  void record(String sha) {
    directory.createSync(recursive: true);
    _file(sha).writeAsStringSync(DateTime.now().toUtc().toIso8601String());
  }

  @override
  bool has(String sha) => _file(sha).existsSync();
}
