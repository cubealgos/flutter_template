import 'package:tooling/src/licence_policy.dart';

/// The four-way outcome of checking one package's licence(s) against the
/// policy in `licence_policy.dart`.
enum LicenceVerdict {
  /// At least one detected licence is on [allowedLicences].
  allowed,

  /// Not on [allowedLicences]; either on [deniedLicences], MPL-2.0 without
  /// a matching exception, an unrecognised pub.dev tag with no matching
  /// verified entry, or a verified entry whose own licence isn't on
  /// [allowedLicences] (never silently passed — see `licence_policy.dart`'s
  /// module doc).
  denied,

  /// Not on [allowedLicences], but a keyed exception in
  /// `tool/licence-exceptions.yaml` covers the exact (package, licence)
  /// pair.
  exempted,

  /// pub.dev reported no recognisable licence at all, but a hand-verified
  /// entry (`verified:` in `tool/licence-exceptions.yaml`) covers the
  /// exact resolved version and its own licence is on [allowedLicences] —
  /// see `verified_licence.dart`.
  verified,
}
