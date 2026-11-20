import 'package:appwrite/appwrite.dart';
import 'package:appwrite_adapters/src/api_client.dart';
import 'package:appwrite_adapters/src/team_function_gateway.dart';

/// The name of the router action this gateway calls.
const String teamAdminAction = 'team_admin';

/// The real `TeamFunctionGateway`, calling the `team_admin` action through
/// `ApiClient`, the only way the app reaches server-side code.
class AppwriteTeamFunctionGateway implements TeamFunctionGateway {
  /// Creates a gateway backed by [client].
  AppwriteTeamFunctionGateway(Client client)
    : this.withApi(ApiClient(Functions(client)));

  /// Creates a gateway over `api`, for tests.
  AppwriteTeamFunctionGateway.withApi(this._api);

  final ApiClient _api;

  @override
  Future<({int statusCode, String body})> execute(
    Map<String, dynamic> fields,
  ) async {
    try {
      final body = await _api.call(teamAdminAction, fields: fields);

      return (statusCode: _ok, body: body);
    } on AppwriteException catch (e) {
      // `ApiClient` reports an action's own failure as "<action> returned
      // <status>: <json body>"; hand that body to the service, which owns
      // the wire format. Anything else (offline, no session) is a transport
      // failure and propagates.
      final message = e.message ?? '';
      final status = e.code;
      final brace = message.indexOf('{');
      if (status == null ||
          !message.startsWith('$teamAdminAction returned') ||
          brace < 0) {
        rethrow;
      }

      return (statusCode: status, body: message.substring(brace));
    }
  }
}

const int _ok = 200;
