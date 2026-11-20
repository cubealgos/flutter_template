import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite_adapters/appwrite_adapters.dart';
import 'package:test/test.dart';

import 'fakes/appwrite_model_fixtures.dart';

const int _ok = 200;
const int _unauthorized = 401;

void main() {
  test('executes the api Function with the action in a JSON body', () async {
    String? sentFunctionId;
    Map<String, dynamic>? sentBody;
    Map<String, dynamic>? sentHeaders;
    final client = ApiClient.withExecutor(({
      required functionId,
      required body,
      required headers,
    }) async {
      sentFunctionId = functionId;
      sentBody = jsonDecode(body) as Map<String, dynamic>;
      sentHeaders = headers;

      return fakeExecution(status: _ok, body: '{"ok":true}');
    });

    final response = await client.call(
      'review_demo_sign_in',
      fields: <String, dynamic>{'code': 'abc'},
    );

    expect(sentFunctionId, 'api');
    expect(ApiClient.functionId, 'api');
    expect(sentBody, <String, dynamic>{
      'action': 'review_demo_sign_in',
      'code': 'abc',
    });
    expect(sentHeaders, <String, dynamic>{'content-type': 'application/json'});
    expect(response, '{"ok":true}');
  });

  test('a field can never override the action', () async {
    Map<String, dynamic>? sentBody;
    final client = ApiClient.withExecutor(({
      required functionId,
      required body,
      required headers,
    }) async {
      sentBody = jsonDecode(body) as Map<String, dynamic>;

      return fakeExecution(status: _ok, body: '{}');
    });

    await client.call(
      'delete_account',
      fields: <String, dynamic>{'action': 'other'},
    );

    expect(sentBody?['action'], 'delete_account');
  });

  test('a non-2xx execution throws an AppwriteException with its status', () {
    final client = ApiClient.withExecutor(
      ({required functionId, required body, required headers}) async =>
          fakeExecution(status: _unauthorized, body: '{"error":"no"}'),
    );

    expect(
      client.call('delete_account'),
      throwsA(
        isA<AppwriteException>()
            .having((e) => e.code, 'code', _unauthorized)
            .having((e) => e.message, 'message', contains('delete_account')),
      ),
    );
  });
}
