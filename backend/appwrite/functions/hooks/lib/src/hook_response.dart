/// A hook's answer.
class HookResponse {
  /// Creates a JSON response.
  const HookResponse({required this.statusCode, required this.body});

  /// The HTTP status. A webhook sender retries on a non-2xx.
  final int statusCode;

  /// The JSON body.
  final Map<String, dynamic> body;
}
