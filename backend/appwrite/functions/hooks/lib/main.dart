import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:hooks/src/hook_request.dart';
import 'package:hooks/src/hook_router.dart';
import 'package:hooks/src/raw_body.dart';
import 'package:hooks/src/registry.dart';

// This entire file talks to a runtime-provided `context` object with no
// static type (see the dartdoc below), so every member access on it is
// necessarily a dynamic call.
// ignore_for_file: avoid_dynamic_calls

/// Appwrite Function entrypoint of `hooks`: the receiver of
/// public, unauthenticated inbound webhooks.
///
/// Deployed via `dart run bin/deploy.dart hooks` from `backend/appwrite/tool/`;
/// `backend/appwrite/schema`'s `templateSchema.functions` declares its ID,
/// `execute: any` (a webhook sender has no session) and its database-only key
/// scopes. A request is routed by its path (`lib/src/registry.dart`); each hook
/// verifies its own signature over the **exact raw body** (`rawBodyOf`).
///
/// `context` is intentionally untyped ([dynamic]) and has no `final`, for the
/// reasons given on `main` in `backend/appwrite/functions/api/lib/main.dart`.
Future<dynamic> main(dynamic context) async {
  final req = context.req;
  final res = context.res;
  final client = Client()
      .setEndpoint(Platform.environment['APPWRITE_FUNCTION_API_ENDPOINT'] ?? '')
      .setProject(Platform.environment['APPWRITE_FUNCTION_PROJECT_ID'] ?? '')
      .setKey((req.headers['x-appwrite-key'] as String?) ?? '');
  final router = HookRouter(
    hooks: hooks,
    log: (message) => context.error(message),
  );

  final response = await router.handle(
    HookRequest(
      method: '${req.method}',
      path: '${req.path}',
      headers: <String, String>{
        for (final entry in (req.headers as Map<dynamic, dynamic>).entries)
          '${entry.key}'.toLowerCase(): '${entry.value}',
      },
      rawBody: rawBodyOf(req),
      environment: Platform.environment,
      client: client,
      log: (message) => context.error(message),
    ),
  );

  return res.json(response.body, response.statusCode);
}
