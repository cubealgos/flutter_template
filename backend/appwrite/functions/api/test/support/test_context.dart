import 'package:api/src/action_context.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

/// An [ActionContext] for a unit test: [environment] and a log sink.
ActionContext testContext({
  String? callerAddress,
  List<String>? logs,
  Map<String, String> environment = const <String, String>{},
}) => ActionContext(
  callerUserId: null,
  body: const <String, dynamic>{},
  environment: environment,
  client: Client(),
  callerAddress: callerAddress,
  log: logs?.add,
);
