import 'package:data/src/version_check_result.dart';
import 'package:data/src/version_policy.dart';

/// A fixed-result [VersionPolicy] for screens and tests.
///
/// Returns [result] regardless of the version passed to [check] — a test
/// sets [result] to a blocking one to exercise the bootstrap flow's
/// "please update" branch without a real backend.
class FakeVersionPolicy implements VersionPolicy {
  /// Creates a fake policy. Defaults to
  /// [VersionCheckResult.allowed] — most screen tests don't care about
  /// version gating and shouldn't have to configure it away.
  FakeVersionPolicy({this.result = VersionCheckResult.allowed});

  /// The result every [check] call returns.
  VersionCheckResult result;

  @override
  Future<VersionCheckResult> check(String currentVersion) async => result;
}
