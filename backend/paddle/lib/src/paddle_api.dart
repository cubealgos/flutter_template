import 'dart:async';
import 'dart:convert';

import 'package:billing/billing.dart';
import 'package:http/http.dart' as http;
import 'package:paddle_billing/src/paddle_api_exception.dart';

/// Paddle's live API base URL (<https://developer.paddle.com/api-reference/overview>).
const String paddleLiveBase = 'https://api.paddle.com';

/// Paddle's sandbox API base URL; a sandbox key only works here.
const String paddleSandboxBase = 'https://sandbox-api.paddle.com';

/// The `proration_billing_mode` a quantity change uses: charge or credit the
/// difference for the rest of the period at once (one of the documented
/// values `prorated_immediately`, `prorated_next_billing_period`,
/// `full_immediately`, `full_next_billing_period`, `do_not_bill`).
const String quantityProrationMode = 'prorated_immediately';

/// The first HTTP status that is not a success.
const int firstErrorStatus = 300;

/// HTTP 404.
const int notFoundStatus = 404;

/// How long one call may take.
const Duration paddleCallTimeout = Duration(seconds: 20);

/// How many pages of subscriptions a listing reads at most.
const int maxListPages = 10;

/// The base URL for an API key: the key says which environment it belongs to
/// (`pdl_sdbx_...` sandbox, `pdl_live_...` live,
/// <https://developer.paddle.com/api-reference/about/authentication>). Any
/// other shape (a legacy key) is refused rather than guessed, so a live key
/// is never used by accident.
String paddleBaseFor(String apiKey) {
  if (apiKey.startsWith('pdl_sdbx_')) return paddleSandboxBase;
  if (apiKey.startsWith('pdl_live_')) return paddleLiveBase;

  throw const PaddleApiException(
    statusCode: 0,
    code: 'unrecognised_key',
    detail: 'PADDLE_API_KEY must start with pdl_sdbx_ or pdl_live_',
  );
}

/// The Paddle Billing REST API, as far as billing needs it.
///
/// Every call is `Authorization: Bearer <key>` with a JSON body, answered by
/// `{"data": ..., "meta": ...}` or `{"error": {"type", "code", "detail"}}`
/// (<https://developer.paddle.com/api-reference/about/errors>). Responses are
/// returned as the entity maps Paddle sends; `PaddleSubscriptionMapper` reads
/// them.
class PaddleApi {
  /// Creates a client over [httpClient] with the API [key]. [baseUrl]
  /// defaults to the one the key belongs to.
  PaddleApi({
    required http.Client httpClient,
    required String key,
    String? baseUrl,
  }) : _client = httpClient,
       _apiKey = key,
       _base = Uri.parse(baseUrl ?? paddleBaseFor(key));

  final http.Client _client;
  final String _apiKey;
  final Uri _base;

  /// Creates a transaction for a checkout (`POST /transactions`) of
  /// [quantity] of [priceId], carrying [owner] in `custom_data` so the
  /// subscription it creates is attributed. Returns the checkout URL
  /// (`checkout.url`, on the approved domain configured in Paddle) and the
  /// transaction ID.
  Future<CheckoutSession> createTransaction({
    required String priceId,
    required int quantity,
    required BillingOwner owner,
    String? customerId,
  }) async {
    final data = await _send('POST', '/transactions', <String, dynamic>{
      'items': <Map<String, dynamic>>[
        <String, dynamic>{'price_id': priceId, 'quantity': quantity},
      ],
      'custom_data': <String, dynamic>{'owner': owner.key},
      'customer_id': ?customerId,
    });
    final checkout = data['checkout'];
    final url = checkout is Map ? checkout['url'] : null;
    if (url is! String || data['id'] is! String) {
      throw const PaddleApiException(
        statusCode: 0,
        code: 'no_checkout_url',
        detail: 'the transaction has no checkout.url',
      );
    }

    return CheckoutSession(
      url: Uri.parse(url),
      transactionId: data['id'] as String,
    );
  }

  /// The subscription [subscriptionId] (`GET /subscriptions/{id}`), or null
  /// when Paddle has none.
  Future<Map<String, dynamic>?> getSubscription(String subscriptionId) async {
    try {
      return await _send('GET', '/subscriptions/$subscriptionId');
    } on PaddleApiException catch (e) {
      if (e.statusCode == notFoundStatus) return null;
      rethrow;
    }
  }

  /// Sets the quantity of [priceId] on [subscriptionId], **prorated**
  /// (`PATCH /subscriptions/{id}`). Paddle removes any item left out of
  /// `items`, so the call sends every item the subscription has, [priceId]'s
  /// with the new [quantity]. Returns the updated subscription.
  Future<Map<String, dynamic>> updateQuantity({
    required String subscriptionId,
    required String priceId,
    required int quantity,
  }) async {
    final current = await getSubscription(subscriptionId);
    if (current == null) {
      throw const PaddleApiException(
        statusCode: notFoundStatus,
        code: 'not_found',
        detail: 'subscription not found',
      );
    }
    final items = <Map<String, dynamic>>[];
    for (final item in (current['items'] as List?) ?? const <Object?>[]) {
      if (item is! Map) continue;
      final price = item['price'];
      final id = price is Map ? price['id'] as String? : null;
      if (id == null) continue;
      items.add(<String, dynamic>{
        'price_id': id,
        'quantity': id == priceId ? quantity : item['quantity'],
      });
    }
    if (!items.any((i) => i['price_id'] == priceId)) {
      items.add(<String, dynamic>{'price_id': priceId, 'quantity': quantity});
    }

    return await _send(
      'PATCH',
      '/subscriptions/$subscriptionId',
      <String, dynamic>{
        'items': items,
        'proration_billing_mode': quantityProrationMode,
      },
    );
  }

  /// A customer-portal session for [customerId]
  /// (`POST /customers/{id}/portal-sessions`), with authenticated links for
  /// [subscriptionIds]. Returns the portal's home (`urls.general.overview`).
  /// The link is temporary: do not store it.
  Future<Uri> createPortalSession({
    required String customerId,
    List<String> subscriptionIds = const <String>[],
  }) async {
    final data = await _send(
      'POST',
      '/customers/$customerId/portal-sessions',
      <String, dynamic>{
        if (subscriptionIds.isNotEmpty) 'subscription_ids': subscriptionIds,
      },
    );
    final urls = data['urls'];
    final general = urls is Map ? urls['general'] : null;
    final overview = general is Map ? general['overview'] : null;
    if (overview is! String) {
      throw const PaddleApiException(
        statusCode: 0,
        code: 'no_portal_url',
        detail: 'the portal session has no urls.general.overview',
      );
    }

    return Uri.parse(overview);
  }

  /// The subscriptions Paddle lists (`GET /subscriptions`, 200 per page,
  /// following `meta.pagination.next` while `has_more`), at most
  /// [maxListPages] pages.
  Future<List<Map<String, dynamic>>> listSubscriptions() async {
    final all = <Map<String, dynamic>>[];
    Uri? next = _base.replace(
      path: '/subscriptions',
      queryParameters: <String, String>{'per_page': '200'},
    );
    for (var page = 0; page < maxListPages && next != null; page++) {
      final body = await _request('GET', next, null);
      final data = body['data'];
      if (data is List) all.addAll(data.whereType<Map<String, dynamic>>());
      final meta = body['meta'];
      final pagination = meta is Map ? meta['pagination'] : null;
      final more = pagination is Map && pagination['has_more'] == true;
      final nextUrl = pagination is Map ? pagination['next'] : null;
      next = more && nextUrl is String ? Uri.tryParse(nextUrl) : null;
    }

    return all;
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final response = await _request(method, _base.replace(path: path), body);
    final data = response['data'];

    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> _request(
    String method,
    Uri url,
    Map<String, dynamic>? body,
  ) async {
    final request = http.Request(method, url)
      ..headers['Authorization'] = 'Bearer $_apiKey'
      ..headers['Content-Type'] = 'application/json';
    if (body != null) request.body = jsonEncode(body);
    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(paddleCallTimeout),
      );
    } on TimeoutException {
      throw const PaddleApiException(
        statusCode: 0,
        code: 'timeout',
        detail: 'Paddle did not answer in time',
      );
    }
    Object? decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      decoded = null;
    }
    final json = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};
    if (response.statusCode >= firstErrorStatus) {
      final error = json['error'];

      throw PaddleApiException(
        statusCode: response.statusCode,
        code: error is Map ? '${error['code']}' : 'http_error',
        detail: error is Map
            ? '${error['detail']}'
            : response.reasonPhrase ?? '',
      );
    }

    return json;
  }
}
