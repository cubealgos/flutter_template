import 'package:api/src/actions/mail_unsubscribe/unsubscribe_page.dart';
import 'package:api/src/actions/mail_unsubscribe/unsubscribe_page_state.dart';
import 'package:api/src/function_response.dart';
import 'package:mailing/mailing.dart';

/// One outcome, rendered as JSON or as a page.
class UnsubscribeReply {
  /// Creates a reply.
  const UnsubscribeReply({
    required this.status,
    required this.state,
    this.errorCode,
    this.token,
    this.locale = MailLocale.fallback,
    this.extra = const <String, dynamic>{},
  });

  /// The HTTP status.
  final int status;

  /// The page state.
  final UnsubscribePageState state;

  /// The error code of a refusal, or null for a success.
  final String? errorCode;

  /// The token, kept so the confirmation form can post it back.
  final String? token;

  /// The language of the page.
  final MailLocale locale;

  /// Extra JSON fields.
  final Map<String, dynamic> extra;

  /// The response, an HTML page when [html].
  FunctionResponse toResponse({required bool html}) {
    final code = errorCode;

    return FunctionResponse(
      statusCode: status,
      body: code == null
          ? <String, dynamic>{'state': state.name, ...extra}
          : <String, dynamic>{
              'error': <String, dynamic>{'code': code, ...extra},
            },
      html: html ? unsubscribePageHtml(state, locale, token: token) : null,
      headers: html ? unsubscribePageHeaders : const <String, String>{},
    );
  }
}
