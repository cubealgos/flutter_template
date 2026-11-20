// Test literals (status codes, times) and `!` on a value the test just made
// are plain in a test and read worse as named constants.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_non_null_assertion, solid_lints/prefer_match_file_name

import 'package:api/src/actions/mail_unsubscribe/handle_unsubscribe_request.dart';
import 'package:api/src/function_response.dart';
import 'package:mailing/mailing.dart';
import 'package:test/test.dart';

final Uri _endpoint = Uri.parse('https://example.test/unsubscribe');

UnsubscribeLinks _links({DateTime Function()? clock, String secret = 's1'}) =>
    UnsubscribeLinks(secret: secret, endpoint: _endpoint, clock: clock);

String _token(UnsubscribeLinks links, {String user = 'u1'}) =>
    links.tokenFor(userId: user, subscription: 'digest', locale: MailLocale.de);

Future<FunctionResponse> _call(
  FakeMailer mailer,
  Map<String, dynamic> body, {
  UnsubscribeLinks? links,
}) => handleUnsubscribeRequest(
  body: body,
  links: links ?? _links(),
  mailer: mailer,
);

String _code(FunctionResponse response) =>
    (response.body['error'] as Map)['code'] as String;

void main() {
  test('a confirmed, correctly signed link unsubscribes exactly its person '
      'and subscription', () async {
    final mailer = FakeMailer();

    final response = await _call(mailer, {
      'token': _token(_links()),
      'confirm': true,
    });

    expect(response.statusCode, 200);
    expect(response.body['state'], 'unsubscribed');
    expect(mailer.store.suppressions, {'u1|digest': 'unsubscribed'});
  });

  test('without confirm it only shows the confirmation and writes nothing '
      '(a scanner that GETs the link unsubscribes no one)', () async {
    final mailer = FakeMailer();

    final response = await _call(mailer, {
      'token': _token(_links()),
      'format': 'html',
    });

    expect(response.statusCode, 200);
    expect(response.body['state'], 'confirm');
    expect(response.html, contains('<form method="post"'));
    expect(response.html, contains('lang="de"'));
    expect(response.headers['Cache-Control'], 'no-store');
    expect(mailer.store.suppressions, isEmpty);
  });

  test('unsubscribing twice answers 200 both times', () async {
    final mailer = FakeMailer();
    final body = {'token': _token(_links()), 'confirm': true};

    await _call(mailer, body);
    final again = await _call(mailer, body);

    expect(again.statusCode, 200);
    expect(again.body['alreadyUnsubscribed'], isTrue);
    expect(mailer.store.suppressions, hasLength(1));
  });

  test(
    'the body cannot widen the scope: only the token names the person',
    () async {
      final mailer = FakeMailer();

      await _call(mailer, {
        'token': _token(_links(), user: 'me'),
        'confirm': true,
        'userId': 'victim',
        'subscription': '*',
      });

      expect(mailer.store.suppressions.keys, ['me|digest']);
    },
  );

  test('a forged, tampered, other-secret or malformed token is a 400 and '
      'writes nothing', () async {
    final mailer = FakeMailer();
    final good = _token(_links());
    final tampered =
        '${_token(_links(), user: 'victim').split('.').first}.'
        '${good.split('.').last}';

    for (final token in [
      tampered,
      _token(_links(secret: 'other')),
      'garbage',
      '',
      null,
      42,
    ]) {
      final response = await _call(mailer, {'token': token, 'confirm': true});

      expect(response.statusCode, 400, reason: '$token');
      expect(_code(response), 'invalid_link');
    }
    expect(mailer.store.suppressions, isEmpty);
  });

  test('an expired link is refused with its reason', () async {
    var now = DateTime.utc(2026, 10);
    final links = _links(clock: () => now);
    final token = _token(links);
    now = now.add(defaultUnsubscribeTtl + const Duration(seconds: 1));
    final mailer = FakeMailer();

    final response = await _call(mailer, {
      'token': token,
      'confirm': true,
    }, links: links);

    expect(response.statusCode, 400);
    expect((response.body['error'] as Map)['reason'], 'expired');
    expect(mailer.store.suppressions, isEmpty);
  });

  test('without a configured secret it answers 503, not a guess', () async {
    final response = await handleUnsubscribeRequest(
      body: {'token': 'x', 'confirm': true},
      links: null,
      mailer: FakeMailer(),
    );

    expect(response.statusCode, 503);
    expect(_code(response), 'not_configured');
  });

  test('an invalid link page is HTML in the fallback locale and escapes '
      'nothing it was not given', () async {
    final response = await _call(FakeMailer(), {
      'token': '<script>',
      'format': 'html',
    });

    expect(response.statusCode, 400);
    expect(response.html, isNot(contains('<script>')));
  });
}
