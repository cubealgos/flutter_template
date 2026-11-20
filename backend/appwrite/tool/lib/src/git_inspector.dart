import 'dart:io';

/// What `Promoter` needs to know about the git checkout.
abstract class GitInspector {
  /// The tag pointing exactly at HEAD, or null if HEAD is untagged.
  Future<String?> exactTag();

  /// The full SHA of HEAD.
  Future<String> headSha();

  /// Whether the working tree has no uncommitted changes.
  Future<bool> isClean();
}

/// [GitInspector] backed by the `git` binary, run in [directory].
class ProcessGitInspector implements GitInspector {
  /// Creates an inspector for the checkout at [directory].
  ProcessGitInspector(this.directory);

  /// The checkout.
  final Directory directory;

  Future<ProcessResult> _git(List<String> args) =>
      Process.run('git', args, workingDirectory: directory.path);

  @override
  Future<String?> exactTag() async {
    final result = await _git(<String>['describe', '--tags', '--exact-match']);
    if (result.exitCode != 0) return null;

    return (result.stdout as String).trim();
  }

  @override
  Future<String> headSha() async =>
      ((await _git(<String>['rev-parse', 'HEAD'])).stdout as String).trim();

  @override
  Future<bool> isClean() async =>
      ((await _git(<String>['status', '--porcelain'])).stdout as String)
          .trim()
          .isEmpty;
}
