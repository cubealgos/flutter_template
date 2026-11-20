import 'package:data/src/version_check_result.dart';

/// Checks the running app's version against a minimum-supported version the
/// backend controls — the first step of the plan's "Bootstrap/splash"
/// default screen ("Resolves the minimum-version check, then the auth
/// session, then feature switches").
///
/// `backend/appwrite/adapters`'s `AppwriteVersionPolicy` is the template's
/// default real implementation, reading a publicly readable config row so
/// the check works before any session exists; `FakeVersionPolicy` is a
/// fixed-result one for screens and tests.
abstract class VersionPolicy {
  /// Checks [currentVersion] (e.g. the app's own package version, a plain
  /// dotted-integer string like `'1.2.3'`) against the backend's minimum
  /// supported version.
  Future<VersionCheckResult> check(String currentVersion);
}
