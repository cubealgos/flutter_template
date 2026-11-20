import 'package:api/src/action_context.dart';
import 'package:api/src/api_action.dart';
import 'package:api/src/api_router.dart' show okStatusCode;
import 'package:api/src/function_response.dart';

/// An [ApiAction] fake that records what the router handed it.
class RecordingAction implements ApiAction {
  /// Creates the fake.
  RecordingAction({
    this.error,
    this.name = 'echo',
    this.requiresUser = true,
    this.scopes = const <String>{},
  });

  @override
  final String name;

  @override
  final bool requiresUser;

  @override
  final Set<String> scopes;

  /// If set, [run] throws this.
  final Exception? error;

  /// Every context [run] was called with.
  final List<ActionContext> runs = <ActionContext>[];

  @override
  String get failureMessage => 'Echo failed.';

  @override
  Future<FunctionResponse> run(ActionContext context) async {
    runs.add(context);
    final failure = error;
    if (failure != null) throw failure;

    return FunctionResponse(
      body: <String, dynamic>{
        'caller': context.callerUserId,
        'body': context.body,
      },
      statusCode: okStatusCode,
    );
  }
}
