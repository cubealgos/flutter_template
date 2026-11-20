import 'package:api/src/action_context.dart';
import 'package:api/src/actions/mail_unsubscribe/handle_unsubscribe_request.dart';
import 'package:api/src/api_action.dart';
import 'package:api/src/function_response.dart';
import 'package:api/src/mail/appwrite_mail_store.dart';
import 'package:api/src/mail/mail_environment.dart';
import 'package:appwrite_schema/appwrite_schema.dart';
import 'package:mailing/mailing.dart';

/// The `mail_unsubscribe` action: the one-click unsubscribe.
///
/// `requiresUser` is **false**: a recipient unsubscribes from an email without
/// signing in, and the authority is the signed token alone (see
/// `handleUnsubscribeRequest`). Two ways in, one handler: the `/unsubscribe`
/// URL of the Function's own domain (what `List-Unsubscribe` points at, see
/// `lib/src/http_entry.dart`: a GET shows the confirmation page, a POST is
/// RFC 8058's one-click), and a plain `{"action": "mail_unsubscribe", ...}`
/// execution for an app or website that prefers JSON.
class MailUnsubscribeAction implements ApiAction {
  /// Creates the action.
  const MailUnsubscribeAction();

  @override
  String get name => 'mail_unsubscribe';

  @override
  bool get requiresUser => false;

  /// Rows of `mail_suppressions`.
  @override
  Set<String> get scopes => const <String>{
    'tables.read',
    'tables.write',
    'collections.read',
    'collections.write',
    'documents.read',
    'documents.write',
  };

  @override
  String get failureMessage => 'Unsubscribing failed.';

  @override
  Future<FunctionResponse> run(ActionContext context) {
    final mailer = MailerEngine(
      store: AppwriteMailStore(
        client: context.client,
        databaseId: templateSchema.databaseId,
      ),
      // Only `unsubscribe` is called, so no transport is ever used.
      transport: _NoTransport(),
      catalog: defaultMailCatalog(),
    );

    return handleUnsubscribeRequest(
      body: context.body,
      links: unsubscribeLinksFrom(context.environment, needBaseUrl: false),
      mailer: mailer,
    );
  }
}

class _NoTransport implements MailTransport {
  @override
  Future<MailTransportResult> send(RenderedMail mail) =>
      throw StateError('mail_unsubscribe never sends.');

  @override
  Future<MailTransportResult?> refresh(String providerMessageId) async => null;
}
