// Test literals (secrets, times) and `!` on a value the test just made are
// plain in a test and read worse as named constants.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_non_null_assertion

import 'package:mailing/mailing.dart';
import 'package:test/test.dart';

final Uri _endpoint = Uri.parse('https://example.test/unsubscribe');

UnsubscribeLinks _links({
  DateTime Function()? clock,
  String secret = 'secret-one',
}) => UnsubscribeLinks(secret: secret, endpoint: _endpoint, clock: clock);

InvalidUnsubscribeReason? _reasonOf(UnsubscribeLinks links, String token) {
  try {
    links.verify(token);
  } on InvalidUnsubscribeLinkError catch (e) {
    return e.reason;
  }

  return null;
}

String _tokenOf(Uri link) => link.queryParameters['t']!;

void main() {
  test('a link verifies to exactly the person, subscription and locale it was '
      'made for', () {
    final links = _links();
    final link = links.linkFor(
      userId: 'u1',
      subscription: 'digest',
      locale: MailLocale.de,
    );

    final claim = links.verify(_tokenOf(link));

    expect(link.toString(), startsWith('https://example.test/unsubscribe?t='));
    expect(claim.userId, 'u1');
    expect(claim.subscription, 'digest');
    expect(claim.locale, MailLocale.de);
  });

  test('a link expires', () {
    var now = DateTime.utc(2026, 10);
    final links = _links(clock: () => now);
    final token = links.tokenFor(
      userId: 'u1',
      subscription: 'digest',
      locale: MailLocale.en,
    );

    now = now.add(defaultUnsubscribeTtl).subtract(const Duration(seconds: 5));
    expect(links.verify(token).userId, 'u1');
    now = now.add(const Duration(seconds: 10));
    expect(_reasonOf(links, token), InvalidUnsubscribeReason.expired);
  });

  test('a token signed with another secret is refused', () {
    final token = _links(
      secret: 'other',
    ).tokenFor(userId: 'u1', subscription: 'digest', locale: MailLocale.en);

    expect(_reasonOf(_links(), token), InvalidUnsubscribeReason.badSignature);
  });

  test('a payload altered to name another person is refused', () {
    final links = _links();
    final victim = links
        .tokenFor(
          userId: 'victim',
          subscription: 'digest',
          locale: MailLocale.en,
        )
        .split('.')
        .first;
    final mine = links
        .tokenFor(userId: 'me', subscription: 'digest', locale: MailLocale.en)
        .split('.')
        .last;

    expect(
      _reasonOf(links, '$victim.$mine'),
      InvalidUnsubscribeReason.badSignature,
    );
  });

  test('a token signed for no purpose of ours is refused', () {
    expect(_reasonOf(_links(), ''), InvalidUnsubscribeReason.malformed);
    expect(_reasonOf(_links(), 'a.b.c'), InvalidUnsubscribeReason.malformed);
    expect(_reasonOf(_links(), 'abc'), InvalidUnsubscribeReason.malformed);
    expect(
      _reasonOf(_links(), 'abc.def'),
      InvalidUnsubscribeReason.badSignature,
    );
  });

  test('an empty secret is refused at construction', () {
    expect(() => _links(secret: ''), throwsArgumentError);
  });
}
