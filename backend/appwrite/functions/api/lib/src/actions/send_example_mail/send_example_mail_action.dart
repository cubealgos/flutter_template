import 'dart:io';

import 'package:api/src/action_context.dart';
import 'package:api/src/actions/send_example_mail/example_mail_sender.dart';
import 'package:api/src/api_action.dart';
import 'package:api/src/function_response.dart';
import 'package:api/src/mail/mail_environment.dart';
import 'package:api/src/rate_limit/rate_limiter.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:mailing/mailing.dart';

/// The `send_example_mail` action: mails the signed-in caller the
/// template's example digest. It is the worked example of sending mail from an
/// action; a clone replaces it with its own (or sends from a scheduled job
/// with `mailerFor`).
class SendExampleMailAction implements ApiAction {
  /// Creates the action.
  const SendExampleMailAction();

  @override
  String get name => 'send_example_mail';

  @override
  bool get requiresUser => true;

  /// Rows of the mail and rate-limit tables, the user's address, Messaging.
  @override
  Set<String> get scopes => const <String>{
    'tables.read',
    'tables.write',
    'collections.read',
    'collections.write',
    'documents.read',
    'documents.write',
    'users.read',
    'messages.read',
    'messages.write',
  };

  @override
  String get failureMessage => 'Sending the mail failed.';

  @override
  Future<FunctionResponse> run(ActionContext context) {
    final caller = context.callerUserId;
    if (caller == null) {
      return Future<FunctionResponse>.value(
        const FunctionResponse(
          statusCode: HttpStatus.unauthorized,
          body: <String, dynamic>{'error': 'Sign in first.'},
        ),
      );
    }
    final users = Users(context.client);
    final secret = context.environment[rateLimitSecretEnvKey];

    return ExampleMailSender(
      mailer: mailerFor(context),
      limiter: secret == null || secret.isEmpty
          ? null
          : RateLimiter.forContext(context),
      lookup: (userId) async {
        final user = await users.get(userId: userId);
        if (!user.emailVerification || user.email.isEmpty) return null;

        return MailRecipient(userId: userId, email: user.email);
      },
    ).handle(caller, context.body);
  }
}
