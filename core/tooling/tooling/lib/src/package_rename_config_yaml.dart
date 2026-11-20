/// Builds the standalone `package_rename_config.yaml` `rename` writes into
/// `apps/app` before shelling out to package_rename (BSD-3-Clause,
/// pub.dev/packages/package_rename) and deletes again once it returns — see
/// `rename_command.dart`.
///
/// Schema confirmed against package_rename 1.10.1's own source
/// (`lib/src/platforms/*.dart` in OutdatedGuy/package_rename): each
/// platform key is optional (a missing key's platform is left untouched),
/// and every value here is written as a quoted YAML scalar so a display
/// name containing `:` or leading/trailing whitespace round-trips exactly.
library;

/// The fields [buildPackageRenameConfigYaml] needs — one per platform
/// output, already resolved by `RenameCommand` (new values from the
/// `--name`/`--org`/`--display` request, [oldApplicationId] read from the
/// clone's current `android/app/build.gradle.kts`).
//
// This file is named for what it does (buildPackageRenameConfigYaml, the
// file's other top-level declaration), not for this plain field-holder
// class — matches `branch_lint_result.dart`'s own convention.
// ignore: solid_lints/prefer_match_file_name
class PackageRenameFields {
  /// Creates the field set for one `rename` run.
  //
  // One independent value per native-platform field package_rename writes
  // (see this class' own fields' dartdoc) — a config object's whole point
  // is one named parameter per setting; same reasoning as `AppConfig`'s
  // constructor in apps/app/lib/app/config.dart.
  // ignore: solid_lints/number_of_parameters
  const PackageRenameFields({
    required this.displayName,
    required this.applicationId,
    required this.exeName,
    required this.organization,
    required this.oldApplicationId,
    required this.androidLang,
    required this.macCopyright,
    required this.windowsCopyright,
  });

  /// The new display name — window title/label/PWA name on every platform.
  final String displayName;

  /// The new `<org>.<name>` application identifier (Android
  /// `applicationId`/`namespace`, iOS/macOS `PRODUCT_BUNDLE_IDENTIFIER`,
  /// Linux `APPLICATION_ID`).
  final String applicationId;

  /// The new Linux/Windows executable name (`--name`, unchanged — package
  /// names are already valid executable names: lowercase, digits,
  /// underscores).
  final String exeName;

  /// The new org (`--org`) — the Windows `CompanyName`.
  final String organization;

  /// The clone's current Android `applicationId`, read before this run
  /// rewrites it — passed as `override_old_package` so package_rename
  /// *moves* `MainActivity.kt`'s package directory instead of leaving a
  /// stale duplicate behind (its own default behaviour without this key).
  final String oldApplicationId;

  /// `kotlin` or `java` — which `MainActivity` template package_rename
  /// writes; detected from whether `android/app/src/main/kotlin` exists.
  final String androidLang;

  /// The new macOS `PRODUCT_COPYRIGHT` value (`OldIdentity.rewriteCopyright`
  /// applied to the clone's current one).
  final String macCopyright;

  /// The new Windows `LegalCopyright` value, same reasoning as
  /// [macCopyright].
  final String windowsCopyright;
}

/// Renders [fields] as a `package_rename_config.yaml` document.
///
/// Deliberately omits `bundle_name` (iOS) and the `web:`/`description` keys:
/// this repo's iOS `CFBundleName` already tracks `CFBundleDisplayName` via
/// package_rename's own `app_name` write (see its `ios.dart`), so a second,
/// possibly-truncated `bundle_name` would just be redundant; and rewriting the
/// web app's `<meta name="description">`/manifest description is out of
/// `rename`'s scope (the title and PWA name are in scope, not the description
/// copy).
String buildPackageRenameConfigYaml(PackageRenameFields fields) {
  String quoted(String value) => "'${value.replaceAll("'", "''")}'";

  return '''
package_rename_config:
  android:
    app_name: ${quoted(fields.displayName)}
    package_name: ${quoted(fields.applicationId)}
    override_old_package: ${quoted(fields.oldApplicationId)}
    lang: ${quoted(fields.androidLang)}

  ios:
    app_name: ${quoted(fields.displayName)}
    package_name: ${quoted(fields.applicationId)}

  macos:
    app_name: ${quoted(fields.displayName)}
    package_name: ${quoted(fields.applicationId)}
    copyright_notice: ${quoted(fields.macCopyright)}

  linux:
    app_name: ${quoted(fields.displayName)}
    package_name: ${quoted(fields.applicationId)}
    exe_name: ${quoted(fields.exeName)}

  windows:
    app_name: ${quoted(fields.displayName)}
    organization: ${quoted(fields.organization)}
    copyright_notice: ${quoted(fields.windowsCopyright)}
    exe_name: ${quoted(fields.exeName)}

  web:
    app_name: ${quoted(fields.displayName)}
    short_app_name: ${quoted(fields.displayName)}
''';
}
