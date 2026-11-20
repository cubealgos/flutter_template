import 'dart:io';

import 'package:api/src/api_router.dart';
import 'package:api/src/http_entry.dart';
import 'package:api/src/registry.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

// This entire file talks to a runtime-provided `context` object with no
// static type (see the dartdoc below), so every member access on it is
// necessarily a dynamic call - the lint exists to catch *accidental*
// dynamic dispatch elsewhere, not this deliberate, documented case.
// ignore_for_file: avoid_dynamic_calls

/// The value of the `x-appwrite-trigger` header on a cron execution.
const String scheduleTrigger = 'schedule';

/// Appwrite Function entrypoint of the one `api` router.
///
/// Deployed via `dart run bin/deploy.dart api` from `backend/appwrite/tool/`
/// (see `backend/appwrite/README.md`); `backend/appwrite/schema`'s
/// `templateSchema.functions` declares this function's ID, runtime, build
/// command, `execute` roles, cron schedule and key scopes.
///
/// A client sends `{"action": "<name>", ...fields}` as JSON; the router
/// (`lib/src/api_router.dart`) authenticates, dispatches to the action in
/// `lib/src/registry.dart` and maps errors. The caller's identity is only
/// ever the `x-appwrite-user-id` header. A cron execution
/// (`x-appwrite-trigger: schedule`) runs the due scheduled jobs instead.
///
/// `context` is intentionally untyped ([dynamic]): the Appwrite Dart runtime
/// builds it itself, from its own internal request/response classes, which
/// aren't published as an importable package - there is no compile-time
/// contract to type this parameter against. The shape this relies on,
/// confirmed against Appwrite's Dart runtime docs: `context.req.bodyJson`
/// (pre-parsed when the caller sends `content-type: application/json`),
/// `context.req.headers` (a `Map` of lowercased header names to values,
/// including the per-execution `x-appwrite-key`, the calling user's
/// `x-appwrite-user-id` and the `x-appwrite-trigger`),
/// `context.res.json(body, statusCode)`, and `context.error(message)`.
///
/// Also intentionally has no `final` before `context`: under this
/// workspace's Dart 3.13 language version, the `final`/`var` parameter
/// modifiers are reserved for the new primary-constructor syntax and are a
/// compile error on an ordinary function parameter otherwise - see
/// `packages/domain/lib/src/account_deletion_result.dart`. Read this
/// signature as `main(dynamic context)`.
Future<dynamic> main(dynamic context) async {
  final req = context.req;
  final res = context.res;
  final env = Platform.environment;

  final client = Client()
      .setEndpoint(env['APPWRITE_FUNCTION_API_ENDPOINT'] ?? '')
      .setProject(env['APPWRITE_FUNCTION_PROJECT_ID'] ?? '')
      .setKey((req.headers['x-appwrite-key'] as String?) ?? '');
  final router = ApiRouter(
    actions: actions,
    jobs: scheduledJobs,
    log: (message) => context.error(message),
  );

  final response = req.headers['x-appwrite-trigger'] == scheduleTrigger
      ? await router.tick(
          now: DateTime.now().toUtc(),
          client: client,
          environment: env,
        )
      : await router.handle(
          rawBody: routerBodyFor(
            method: '${req.method}',
            path: '${req.path}',
            query: _queryOf(req),
            bodyJson: _bodyOf(req),
          ),
          callerUserId: req.headers['x-appwrite-user-id'] as String?,
          callerAddress: _firstAddress(req.headers['x-forwarded-for']),
          client: client,
          environment: env,
        );

  final html = response.html;
  if (html != null) {
    return res.text(html, response.statusCode, <String, String>{
      'content-type': 'text/html; charset=utf-8',
      ...response.headers,
    });
  }

  return res.json(response.body, response.statusCode, response.headers);
}

/// The request's query parameters as a map, or null.
Map<String, dynamic>? _queryOf(dynamic req) {
  try {
    final query = req.query as Map<dynamic, dynamic>?;

    return query == null
        ? null
        : <String, dynamic>{for (final e in query.entries) '${e.key}': e.value};
  } on Object {
    return null;
  }
}

/// The request's parsed JSON body, or null when it has none or it is not
/// JSON (the router answers that with a 400).
Object? _bodyOf(dynamic req) {
  try {
    return req.bodyJson as Object?;
  } on Object {
    return null;
  }
}

/// The first address of an `x-forwarded-for` header value, or null.
String? _firstAddress(Object? header) {
  if (header is! String) return null;
  final first = header.split(',').first.trim();

  return first.isEmpty ? null : first;
}
