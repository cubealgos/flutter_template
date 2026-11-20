/// Validation and pure derivation for `rename`'s identity fields — the new
/// `--name`/`--org`/`--display`/`--app-package` values, and the *old*
/// values read out of a not-yet-renamed clone (`flutter_template`'s own
/// placeholder identity, or whatever an earlier `tooling:rename` run left
/// behind). Kept dependency-free (no `dart:io`) so every function here is
/// exercised directly against literal strings in
/// `rename_identity_test.dart`, never through a filesystem fixture.
library;

/// Lowercase `snake_case`: starts with a lowercase letter, then any run of
/// lowercase letters, digits or underscores. Matches Dart's own package-name
/// convention (see `--name`'s app package and `--app-package`).
final RegExp snakeCaseNamePattern = RegExp(r'^[a-z][a-z0-9_]*$');

/// A reverse-domain identifier: two or more dot-separated segments, each a
/// lowercase letter followed by lowercase letters/digits (no segment starts
/// with a digit, matching Java/Kotlin/Swift package-identifier rules that
/// Android's `applicationId`/`namespace` and iOS/macOS's
/// `PRODUCT_BUNDLE_IDENTIFIER` both inherit).
final RegExp reverseDomainOrgPattern = RegExp(
  r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$',
);

/// True if [value] is a valid `--name`/`--app-package` value.
bool isValidSnakeCaseName(String value) => snakeCaseNamePattern.hasMatch(value);

/// True if [value] is a valid `--org` value.
bool isValidReverseDomainOrg(String value) =>
    reverseDomainOrgPattern.hasMatch(value);

/// The four fields a `rename` invocation requests, already validated by the
/// time a `RenameRequest` exists — see `rename_command.dart`'s
/// `_parseArgs`/`_validateRequest`.
//
// This file is named for what it holds (rename's identity values, old and
// new), not for this — the file's first-declared — class; the second class
// below (`OldIdentity`) is the file's namesake concept just as much.
// ignore: solid_lints/prefer_match_file_name
class RenameRequest {
  /// Creates a validated rename request.
  const RenameRequest({
    required this.name,
    required this.org,
    required this.display,
    this.appPackage,
  });

  /// The new snake_case app name (`--name`) — becomes the Android/iOS/macOS/
  /// Linux/Windows package identifier's last segment, the Linux executable
  /// name, and (with `_workspace` appended) the workspace root pubspec's
  /// `name:`.
  final String name;

  /// The new reverse-domain org (`--org`) — becomes the Android/iOS/macOS/
  /// Linux application identifier's prefix and the Windows organization
  /// name.
  final String org;

  /// The new human-readable display name (`--display`) — becomes every
  /// platform's window title/label/PWA name and the `appTitle` i18n string.
  final String display;

  /// The new Dart package name for `apps/app`, or `null` to keep the
  /// existing one (the default — see `rename_command.dart`'s dartdoc for
  /// why a clone-per-app template doesn't need this changed).
  final String? appPackage;

  /// The Android/iOS/macOS/Linux application identifier this request
  /// implies: `<org>.<name>`.
  String get applicationId => '$org.$name';

  /// The new workspace root pubspec `name:` this request implies:
  /// `<name>_workspace`.
  String get workspaceName => '${name}_workspace';
}

/// Every old-identity value `RenameCommand` needs, read out of the clone
/// being renamed before anything is rewritten. Each field is read from a
/// different file — see `rename_command.dart`'s `_readOldIdentity` — so
/// this class only holds already-extracted strings, keeping the rest of
/// this file's logic (its [org]/[templateToken]/[rewriteCopyright] getters)
/// pure and unit-testable.
class OldIdentity {
  /// Creates an old-identity snapshot.
  //
  // Six independent facts read from six different files — see
  // `rename_command.dart`'s `_readOldIdentity` — not behaviour parameters,
  // so grouping them further wouldn't reduce the real count (same
  // reasoning as `AppConfig`'s constructor in apps/app/lib/app/config.dart).
  // ignore: solid_lints/number_of_parameters
  const OldIdentity({
    required this.workspaceName,
    required this.appPackageName,
    required this.applicationId,
    required this.displayName,
    required this.macCopyright,
    required this.windowsCopyright,
  });

  /// The current workspace root pubspec `name:` (e.g.
  /// `flutter_template_workspace`).
  final String workspaceName;

  /// The current `apps/app` pubspec `name:` (e.g. `app`).
  final String appPackageName;

  /// The current Android `applicationId` (e.g. `com.example.app`) — also
  /// where the current org and Kotlin package directory are derived from.
  final String applicationId;

  /// The current `appTitle` i18n placeholder (e.g. `flutter_template`).
  final String displayName;

  /// The current macOS `PRODUCT_COPYRIGHT` value (e.g. `Copyright © 2026
  /// com.example. All rights reserved.`), reused (with the org substring
  /// swapped) rather than rebuilt from scratch — see
  /// [OldIdentity.rewriteCopyright] — so the year and phrasing survive a
  /// rename untouched.
  final String macCopyright;

  /// The current Windows `LegalCopyright` value (e.g. `Copyright (C) 2026
  /// com.example. All rights reserved.`), same reasoning as [macCopyright].
  final String windowsCopyright;

  /// The org this identity's [applicationId] implies: everything before the
  /// last `.`-separated segment (e.g. `com.example.app` → `com.example`).
  /// Deriving it this way — rather than assuming it equals [applicationId]
  /// minus [appPackageName] — stays correct even if the two have already
  /// diverged (e.g. after an `--app-package` rename).
  String get org {
    final lastDot = applicationId.lastIndexOf('.');
    if (lastDot < 0) return applicationId;

    return applicationId.substring(0, lastDot);
  }

  /// The `flutter_template`-shaped token every generic text rewrite step
  /// searches for and replaces: [workspaceName] with a trailing `_workspace`
  /// stripped, if present.
  String get templateToken {
    const suffix = '_workspace';

    return workspaceName.endsWith(suffix)
        ? workspaceName.substring(0, workspaceName.length - suffix.length)
        : workspaceName;
  }

  /// The case-insensitive search terms `rename`'s final leftover check
  /// looks for once every rewrite step has run: [templateToken] (and its
  /// space-separated variant, e.g. `flutter template`), [org] and
  /// [displayName] — the same four categories CLAUDE.md's `rename` row
  /// documents. Empty terms (an [OldIdentity] built with a blank
  /// [displayName], say) are dropped rather than matching every file.
  Set<String> get leftoverSearchTerms => <String>{
    templateToken,
    templateToken.replaceAll('_', ' '),
    org,
    displayName,
  }.where((term) => term.trim().isNotEmpty).toSet();

  /// [macCopyright] or [windowsCopyright] with every occurrence of [org]
  /// replaced by [newOrg] — the whole point being that the surrounding
  /// phrasing and year are copied forward unchanged.
  String rewriteCopyright(String copyright, String newOrg) =>
      copyright.replaceAll(org, newOrg);
}
