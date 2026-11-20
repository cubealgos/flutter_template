import 'package:billing/billing.dart';
import 'package:paddle_billing/src/paddle_plans.dart';
import 'package:paddle_billing/src/paddle_signature.dart';

/// The Function variables that configure billing.
///
/// - `PADDLE_API_KEY` (secret): a Paddle API key, `pdl_sdbx_...` or
///   `pdl_live_...`; it decides sandbox or live.
/// - `PADDLE_WEBHOOK_SECRET` (secret): the notification destination's secret
///   key; the `hooks` Function verifies every webhook with it.
/// - `PADDLE_PLANS`: JSON `{"<plan key>": "<price id>"}`.
/// - `BILLING_GRACE_DAYS`: how long a past-due subscription keeps access
///   (default 7).
/// - `PADDLE_SIGNATURE_TOLERANCE_SECONDS`: the signature timestamp tolerance
///   (default 60).
class PaddleConfig {
  /// Creates a configuration.
  const PaddleConfig({
    required this.plans,
    required this.policy,
    required this.signatureTolerance,
    this.apiKey,
    this.webhookSecret,
  });

  /// Reads the configuration from [environment]. A malformed value throws a
  /// [FormatException], so a typo fails visibly instead of silently using a
  /// default.
  factory PaddleConfig.fromEnvironment(Map<String, String> environment) {
    String? text(String key) {
      final value = environment[key]?.trim();

      return value == null || value.isEmpty ? null : value;
    }

    int? whole(String key) {
      final value = text(key);
      if (value == null) return null;

      return int.tryParse(value) ??
          (throw FormatException('$key must be a whole number'));
    }

    final graceDays = whole('BILLING_GRACE_DAYS');
    final toleranceSeconds = whole('PADDLE_SIGNATURE_TOLERANCE_SECONDS');

    return PaddleConfig(
      apiKey: text('PADDLE_API_KEY'),
      webhookSecret: text('PADDLE_WEBHOOK_SECRET'),
      plans: PaddlePlans.parse(text('PADDLE_PLANS')),
      policy: graceDays == null
          ? const EntitlementPolicy()
          : EntitlementPolicy(grace: Duration(days: graceDays)),
      signatureTolerance: toleranceSeconds == null
          ? PaddleSignature.defaultTolerance
          : Duration(seconds: toleranceSeconds),
    );
  }

  /// The API key, or null when billing calls are not configured.
  final String? apiKey;

  /// The webhook secret, or null when webhooks are not configured.
  final String? webhookSecret;

  /// The plans.
  final PaddlePlans plans;

  /// The grace period.
  final EntitlementPolicy policy;

  /// The signature timestamp tolerance.
  final Duration signatureTolerance;
}
