// Test literals, `late` set-up fixtures and a group's long body are plain in a
// test and read worse as named constants or splits.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_late_keyword, solid_lints/prefer_match_file_name, solid_lints/number_of_parameters, solid_lints/function_lines_of_code, solid_lints/avoid_non_null_assertion

import 'package:hooks/src/hook_request.dart';
import 'package:hooks/src/hook_response.dart';
import 'package:hooks/src/hook_router.dart';
import 'package:hooks/src/webhook_hook.dart';
import 'package:test/test.dart';

import 'support.dart';

class _Hook implements WebhookHook {
  _Hook(this.path, this.run);

  @override
  final String path;
  final Future<HookResponse> Function() run;

  @override
  Future<HookResponse> handle(HookRequest request) => run();
}

void main() {
  const ok = HookResponse(statusCode: 200, body: <String, dynamic>{});

  test(
    'routes by path, ignoring a query string and a trailing slash',
    () async {
      final router = HookRouter(hooks: [_Hook('/a', () async => ok)]);

      for (final path in ['/a', '/a/', '/a?x=1']) {
        final request = paddleRequest(const <int>[]);
        final response = await router.handle(
          HookRequest(
            method: 'POST',
            path: path,
            headers: request.headers,
            rawBody: request.rawBody,
            environment: request.environment,
            client: request.client,
          ),
        );
        expect(response.statusCode, 200, reason: path);
      }
    },
  );

  test('an unknown path is 404 and a non-POST is 405', () async {
    final router = HookRouter(hooks: [_Hook('/paddle', () async => ok)]);

    expect(
      (await router.handle(
        paddleRequest(const []).withPath('/nope'),
      )).statusCode,
      404,
    );
    expect(
      (await router.handle(
        paddleRequest(const []).withMethod('GET'),
      )).statusCode,
      405,
    );
  });

  test(
    'a hook that throws is a generic 500 and the cause only in the log',
    () async {
      final logs = <String>[];
      final router = HookRouter(
        hooks: [_Hook('/paddle', () async => throw Exception('secret-detail'))],
        log: logs.add,
      );

      final response = await router.handle(paddleRequest(const []));

      expect(response.statusCode, 500);
      expect(response.body.toString(), isNot(contains('secret-detail')));
      expect(logs.single, contains('secret-detail'));
    },
  );

  test('a duplicate path is refused', () {
    expect(
      () => HookRouter(
        hooks: [_Hook('/a', () async => ok), _Hook('/a', () async => ok)],
      ),
      throwsArgumentError,
    );
  });
}

extension on HookRequest {
  HookRequest withPath(String path) => HookRequest(
    method: method,
    path: path,
    headers: headers,
    rawBody: rawBody,
    environment: environment,
    client: client,
  );

  HookRequest withMethod(String method) => HookRequest(
    method: method,
    path: path,
    headers: headers,
    rawBody: rawBody,
    environment: environment,
    client: client,
  );
}
