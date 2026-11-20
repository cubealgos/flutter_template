import 'package:appwrite_tool/src/review_demo_account_gateway.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

/// The real [ReviewDemoAccountGateway], backed by `package:dart_appwrite`'s
/// `Users` and `Functions` services.
class DartAppwriteReviewDemoAccountGateway implements ReviewDemoAccountGateway {
  /// Creates a gateway backed by [client].
  DartAppwriteReviewDemoAccountGateway(Client client)
    : _users = Users(client),
      _functions = Functions(client);

  final Users _users;
  final Functions _functions;

  @override
  Future<String?> findUserIdByEmail(String email) async {
    final result = await _users.list(
      queries: <String>[Query.equal('email', email)],
    );
    if (result.users.isEmpty) return null;

    // Appwrite enforces unique emails, so there's at most one match; `.first`
    // (not `.single`) is defensive rather than a real ambiguity this method
    // needs to resolve.
    return result.users.first.$id;
  }

  @override
  Future<String> createUser({required String email}) async {
    // No `password:` argument - see this gateway's interface dartdoc for
    // why.
    final user = await _users.create(
      userId: ID.unique(),
      email: email,
      name: 'App Review Demo',
    );

    return user.$id;
  }

  @override
  Future<void> verifyEmail(String userId) async {
    await _users.updateEmailVerification(
      userId: userId,
      emailVerification: true,
    );
  }

  @override
  Future<bool> functionVariableHasValue({
    required String functionId,
    required String key,
  }) async {
    final result = await _functions.listVariables(functionId: functionId);

    // A *secret* variable's value is never returned by the API (Appwrite
    // Cloud creates every function variable secret by default), so blank
    // is unobservable there: it counts as set. Only a non-secret
    // variable's value can be checked for blankness.
    return result.variables.any(
      (variable) =>
          variable.key == key &&
          (variable.secret || variable.value.trim().isNotEmpty),
    );
  }

  @override
  Future<void> setFunctionVariable({
    required String functionId,
    required String key,
    required String value,
  }) async {
    final result = await _functions.listVariables(functionId: functionId);
    final existing = result.variables.where((variable) => variable.key == key);

    if (existing.isEmpty) {
      await _functions.createVariable(
        functionId: functionId,
        variableId: ID.unique(),
        key: key,
        value: value,
      );
    } else {
      await _functions.updateVariable(
        functionId: functionId,
        variableId: existing.first.$id,
        value: value,
      );
    }
  }
}
