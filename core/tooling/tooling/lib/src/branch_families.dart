/// The six working-branch families this repo's workflow tooling recognizes,
/// the branch-name shapes derived from them, and which base branch each
/// family branches from.
///
/// This is the single source of truth [branchFamilies] list: both
/// `branch_new` (validating a requested family) and `branch_lint`
/// (validating existing branch names) read it from here, so the two can
/// never drift apart on what a "family" is.
library;

/// The six branch families, in the canonical order used in error messages.
///
/// The branch model's normative rules, applied to GitHub issues.
const List<String> branchFamilies = <String>[
  'feature',
  'bugfix',
  'chore',
  'documentation',
  'release',
  'hotfix',
];

/// Families whose working branches are cut from `production` instead of the
/// usual `development`.
const List<String> productionBaseFamilies = <String>['hotfix'];

/// The two long-lived branches, exempt from [branchNamePattern] and
/// [releasePackageVersionPattern] entirely.
const List<String> longLivedBranches = <String>['production', 'development'];

/// Lowercase kebab-case: one or more lowercase-alphanumeric segments joined
/// by single hyphens, no leading/trailing/doubled hyphens.
final RegExp slugPattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

/// The ordinary working-branch name shape: `<family>/<N>-<slug>`, where `N`
/// is a GitHub issue number and `<slug>` is [slugPattern]-shaped.
final RegExp branchNamePattern = RegExp(
  '^(${branchFamilies.join('|')})/\\d+-[a-z0-9]+(-[a-z0-9]+)*\$',
);

/// The alternate shape allowed only for `release/*` branches:
/// `release/<pkg>-v<semver>` (a package name, then `-v`, then a semantic
/// version — optionally with a pre-release and/or build-metadata suffix).
final RegExp releasePackageVersionPattern = RegExp(
  r'^release/[a-z0-9]+(-[a-z0-9]+)*-v\d+\.\d+\.\d+'
  r'(-[0-9A-Za-z-.]+)?(\+[0-9A-Za-z-.]+)?$',
);

/// Returns the base branch [family] is cut from: `production` for
/// [productionBaseFamilies], `development` for every other family.
String baseBranchFor(String family) =>
    productionBaseFamilies.contains(family) ? 'production' : 'development';

/// The `type/*` GitHub label each family maps to, for `branch_new` to
/// apply alongside `status/in-progress`. `release` and `hotfix` are
/// deliberately absent: the repo has no `type/release`/`type/hotfix` label
/// (verified against `gh label list --repo {o}/{r}`), so `branch_new`
/// doesn't attempt to add one for those two families — add an entry here
/// if such a label is ever created.
const Map<String, String> typeLabelByFamily = <String, String>{
  'feature': 'type/feature',
  'bugfix': 'type/bugfix',
  'chore': 'type/chore',
  'documentation': 'type/docs',
};

/// The `type/*` label [family] maps to, or `null` if [family] has none
/// (see [typeLabelByFamily]).
String? typeLabelFor(String family) => typeLabelByFamily[family];
