import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite_schema/appwrite_schema.dart';

/// Runs one execution of a Function: the shape of `Functions.createExecution`
/// this client needs, so a test can stand in for the network.
typedef FunctionExecutor = Future<models.Execution> Function({
  required String functionId,
  required String body,
  required Map<String, dynamic> headers,
});

/// The one way the app reaches server-side code: calls a named action of the
/// `api` router Function (`backend/appwrite/functions/api`).
///
/// No other code in the app or the adapters knows a Function id; adding an
/// action means adding a caller of [call], never a new id.
class ApiClient {
  /// Creates a client executing through [functions].
  ApiClient(Functions functions)
    : this.withExecutor(
        ({required functionId, required body, required headers}) =>
            functions.createExecution(
              functionId: functionId,
              body: body,
              headers: headers,
              xasync: false,
            ),
      );

  /// Creates a client over a custom [executor], for tests.
  ApiClient.withExecutor(FunctionExecutor executor) : _execute = executor;

  /// The router Function's ID, read from the schema `backend/` and this
  /// adapter both depend on - see `backend/appwrite/schema`'s
  /// `templateSchema`.
  static final String functionId = templateSchema.functions
      .singleWhere((function) => function.id == 'api')
      .id;

  /// The inclusive lower bound of a non-success HTTP status: anything at or
  /// above this means the action itself reported failure (a validation 4xx,
  /// the router's 401/404, or the action's 500), not "ran and returned this
  /// JSON body".
  static const int _httpErrorStatusStart = 300;

  final FunctionExecutor _execute;

  /// Executes [action] with the extra body [fields] and returns the
  /// response body.
  ///
  /// Throws [AppwriteException], carrying the execution's own HTTP status,
  /// for any non-2xx response. The caller's identity is never sent: the
  /// router reads it from the execution's session header.
  Future<String> call(
    String action, {
    Map<String, dynamic> fields = const <String, dynamic>{},
  }) async {
    final execution = await _execute(
      functionId: functionId,
      body: jsonEncode(<String, dynamic>{...fields, 'action': action}),
      // The router's `context.req.bodyJson` is only pre-parsed to a Map
      // when the request declares this content type.
      headers: <String, dynamic>{'content-type': 'application/json'},
    );

    if (execution.responseStatusCode >= _httpErrorStatusStart) {
      throw AppwriteException(
        '$action returned ${execution.responseStatusCode}: '
        '${execution.responseBody}',
        execution.responseStatusCode,
      );
    }

    return execution.responseBody;
  }
}
