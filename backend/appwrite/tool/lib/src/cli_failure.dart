import 'package:appwrite_tool/src/backend_env.dart';
import 'package:appwrite_tool/src/deploy/site_deployer.dart';
import 'package:appwrite_tool/src/promoter.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

const int _unauthorized = 401;
final RegExp _missingScopes = RegExp(r'missing scopes? \((\[[^\]]*\])\)');

/// One line describing [error] for an operator: the [target] project, the
/// [operation], Appwrite's message and, for a missing-scope 401, the scopes
/// and where to find the key checklist.
String describeAppwriteFailure({
  required String target,
  required String operation,
  required AppwriteException error,
}) {
  final message = error.message ?? error.type ?? 'unknown error';
  final line = StringBuffer('$operation failed on $target: $message');
  if (error.code == _unauthorized &&
      error.type == 'general_unauthorized_scope') {
    final scopes = _missingScopes.firstMatch(message)?.group(1);
    line.write(
      ' -- the API key lacks ${scopes ?? 'a required scope'}; '
      'run `dart run bin/api_keys.dart` for the checklist that creates the '
      'right scoped key.',
    );
  }

  return line.toString().replaceAll('\n', ' ');
}

/// Runs [body] (which returns the exit code) and turns an Appwrite failure
/// or one of this tool's own refusals into one line on [err] and a non-zero
/// exit code, never a stack trace.
Future<int> runReportingFailures({
  required String target,
  required String operation,
  required Future<int> Function() body,
  required void Function(String line) err,
}) async {
  try {
    return await body();
  } on AppwriteException catch (e) {
    err(
      describeAppwriteFailure(target: target, operation: operation, error: e),
    );
  } on PromotionRefusedException catch (e) {
    err('$operation on $target: $e');
  } on SiteBuildMissingException catch (e) {
    err('$operation on $target: $e');
  } on ProductionNotConfirmedException catch (e) {
    err('$operation on $target: $e');
  } on MissingBackendConfigException catch (e) {
    err('$operation on $target: $e');
  }

  return 1;
}
