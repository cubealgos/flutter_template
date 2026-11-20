/// The Conventional Commits rule this repo enforces on every commit subject
/// line (the first line of a commit message).
///
/// Shape: `type(scope)!: description (#N)`
/// - `type` is one of [commitTypes].
/// - `(scope)` is required — lowercase letters, digits, `.`, `_`, `/`, `-`.
/// - an optional `!` marks a breaking change.
/// - `description` is free text.
/// - the subject must end with an issue reference `(#N)`.
///
/// There is no exemption for merge commits, release commits, fixup commits
/// or squash commits: a merge commit's subject is the PR title, which must
/// itself conform (e.g. `merge(repo): feature/1-x into development (#1)`); a
/// release commit conforms the same way (e.g. `release(app): 1.2.0 (#9)`);
/// and `fixup!`/`squash!` prefixed subjects are rejected outright.
library;

/// The allowed Conventional Commits types for this repository.
///
/// `merge` and `release` are included alongside the usual Conventional
/// Commits types — every commit
/// conforms, merges and releases included, so both need a scope and an
/// issue reference exactly like any other commit.
const List<String> commitTypes = <String>[
  'feat',
  'fix',
  'docs',
  'style',
  'refactor',
  'perf',
  'test',
  'build',
  'ci',
  'chore',
  'revert',
  'merge',
  'release',
];

/// The regular expression a commit subject line must match.
///
/// Group 1 is the type, group 2 is the scope (including parens), group 3 is
/// the optional `!`.
final RegExp commitSubjectPattern = RegExp(
  '^(${commitTypes.join('|')}'
  r')(\([a-z0-9._/-]+\))!?: .+ \(#\d+\)$',
);

/// The human-readable statement of the rule, used in error messages.
final String commitRuleDescription =
    'Commit subject must match: '
    '<type>(<scope>): <description> (#<issue>) — '
    'type is one of ${commitTypes.join(', ')}, '
    'scope is required (lowercase letters, digits, ., _, /, -), '
    'and the subject must end with an issue reference such as. '
    'An optional "!" before the colon marks a breaking change. '
    'fixup!/squash! prefixes and merge commits are not exempt.';

/// Returns null if [subject] satisfies the commit rule, otherwise a
/// human-readable reason it does not.
String? validateCommitSubject(String subject) {
  final trimmed = subject.trimRight();
  if (trimmed.isEmpty) {
    return 'Commit subject is empty. $commitRuleDescription';
  }
  if (trimmed.startsWith('fixup!') || trimmed.startsWith('squash!')) {
    return 'fixup!/squash! commit subjects are not allowed: "$trimmed". '
        '$commitRuleDescription';
  }
  if (!commitSubjectPattern.hasMatch(trimmed)) {
    return 'Commit subject "$trimmed" does not match the required format. '
        '$commitRuleDescription';
  }

  return null;
}

/// Returns true if [subject] satisfies the commit rule.
bool isValidCommitSubject(String subject) =>
    validateCommitSubject(subject) == null;
