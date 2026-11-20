import 'dart:convert';

/// The product's plans: the plan key the app uses and the Paddle price ID it
/// is sold as (`pri_...`).
class PaddlePlans {
  /// Creates the mapping from plan key to price ID.
  const PaddlePlans(this.priceIds);

  /// Parses the `PADDLE_PLANS` variable, a JSON object `{"pro": "pri_..."}`.
  /// Null or empty is no plans; anything else that is not such an object
  /// throws a [FormatException].
  factory PaddlePlans.parse(String? json) {
    if (json == null || json.trim().isEmpty) {
      return const PaddlePlans(<String, String>{});
    }
    final decoded = jsonDecode(json);
    if (decoded is! Map) {
      throw const FormatException('PADDLE_PLANS must be a JSON object');
    }

    return PaddlePlans(<String, String>{
      for (final entry in decoded.entries)
        if (entry.value is String) '${entry.key}': entry.value as String,
    });
  }

  /// Plan key to price ID.
  final Map<String, String> priceIds;

  /// The price ID of [plan], or null if it is not sold.
  String? priceFor(String plan) => priceIds[plan];

  /// The plan key a price ID is sold as; the price ID itself when unknown, so
  /// a price added in Paddle's dashboard is visible rather than lost.
  String planFor(String priceId) {
    for (final entry in priceIds.entries) {
      if (entry.value == priceId) return entry.key;
    }

    return priceId;
  }
}
