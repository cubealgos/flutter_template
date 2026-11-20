import 'package:path/path.dart' as p;
import 'package:tooling/src/command_failure.dart';
import 'package:tooling/src/process_runner.dart';

/// The git host, owner and repo slug parsed from a git remote URL. `host`
/// isn't used to build a `GitHubClient` — `gh` always talks to
/// `github.com` (or its own configured enterprise host) on its own — but
/// is kept for the local-path fallback tests use and for diagnostics.
class GitRemoteInfo {
  /// Creates a remote descriptor.
  const GitRemoteInfo({
    required this.host,
    required this.owner,
    required this.repo,
  });

  /// The git host, e.g. `github.com`.
  final String host;

  /// The repository owner (user or org), e.g. `example-org`.
  final String owner;

  /// The repository name, e.g. `my_app`.
  final String repo;
}

/// An `https://` or `ssh` (`git@host:owner/repo.git`) remote URL, parsed
/// into a [GitRemoteInfo].
final RegExp _httpsRemotePattern = RegExp(
  r'^https?://(?:[^/@]+@)?([^/]+?)(?::\d+)?/([^/]+)/([^/]+?)(\.git)?/?$',
);
final RegExp _sshRemotePattern = RegExp(
  r'^(?:ssh://)?git@([^:/]+)(?::\d+)?[:/]([^/]+)/([^/]+?)(\.git)?/?$',
);

/// Capture-group indices shared by [_httpsRemotePattern] and
/// [_sshRemotePattern]: host, owner, repo, in that order.
const int _ownerGroup = 2;
const int _repoGroup = 3;

/// Reads `origin`'s URL via [runner] from [repoDir] and parses it into a
/// [GitRemoteInfo]. Throws [CommandFailure] if `git remote get-url` fails
/// or the URL doesn't match a recognized shape.
Future<GitRemoteInfo> resolveGitRemote(
  ProcessRunner runner,
  String repoDir,
) async {
  final result = await runner.run('git', [
    'remote',
    'get-url',
    'origin',
  ], workingDirectory: repoDir);
  if (result.exitCode != 0) {
    throw CommandFailure('git remote get-url origin failed: ${result.stderr}');
  }

  return parseGitRemoteUrl((result.stdout as String).trim());
}

/// Parses a git remote [url] into a [GitRemoteInfo]: `https://`,
/// `git@host:owner/repo.git`, or a plain local path shaped
/// `.../<owner>/<repo>.git` (a `host` of `local` — used by, e.g., a bare
/// repo fixture in tests, which has no real `github.com` host). Throws
/// [CommandFailure] if [url] matches none of those shapes.
GitRemoteInfo parseGitRemoteUrl(String url) {
  final info =
      _tryParse(_httpsRemotePattern, url) ??
      _tryParse(_sshRemotePattern, url) ??
      _tryParseLocalPath(url);
  if (info == null) {
    throw CommandFailure('Cannot parse git remote URL: "$url".');
  }

  return info;
}

GitRemoteInfo? _tryParse(RegExp pattern, String url) {
  final match = pattern.firstMatch(url);
  if (match == null) return null;

  return GitRemoteInfo(
    host: match.group(1) ?? '',
    owner: match.group(_ownerGroup) ?? '',
    repo: match.group(_repoGroup) ?? '',
  );
}

/// How many trailing path segments before the repo segment hold the owner
/// (i.e. `owner/repo.git` — the owner is 2 segments from the end).
const int _ownerSegmentsFromEnd = 2;

const String _fileScheme = 'file://';

GitRemoteInfo? _tryParseLocalPath(String url) {
  if (url.contains('://') && !url.startsWith(_fileScheme)) return null;
  final path = url.startsWith(_fileScheme)
      ? url.substring(_fileScheme.length)
      : url;
  if (!p.isAbsolute(path)) return null;

  final segments = p.split(path).where((s) => s != p.separator).toList();
  if (segments.length < _ownerSegmentsFromEnd) return null;

  return GitRemoteInfo(
    host: 'local',
    owner: segments[segments.length - _ownerSegmentsFromEnd],
    repo: p.basenameWithoutExtension(segments.last),
  );
}
