// A `!` on a value the test just made is plain in a test.
// ignore_for_file: solid_lints/avoid_non_null_assertion
import 'package:api/src/http_entry.dart';
import 'package:test/test.dart';

void main() {
  test(
    'a POST to /unsubscribe is a confirmed unsubscribe asking for a page',
    () {
      final body = routerBodyFor(
        method: 'POST',
        path: '/unsubscribe',
        query: {'t': 'tok'},
        bodyJson: null,
      );

      expect(body, {
        'action': 'mail_unsubscribe',
        'token': 'tok',
        'confirm': true,
        'format': 'html',
      });
    },
  );

  test('a GET (or HEAD) only asks to confirm', () {
    for (final method in ['GET', 'HEAD']) {
      final body =
          routerBodyFor(
                method: method,
                path: '/unsubscribe',
                query: {'t': 'tok'},
                bodyJson: null,
              )!
              as Map<String, dynamic>;

      expect(body['confirm'], isFalse, reason: method);
    }
  });

  test('any other path passes the JSON body through untouched', () {
    final json = {'action': 'jobs'};

    expect(
      routerBodyFor(method: 'POST', path: '/', query: null, bodyJson: json),
      same(json),
    );
  });

  test('a missing token becomes an empty one, which the action refuses', () {
    final body =
        routerBodyFor(
              method: 'POST',
              path: '/unsubscribe',
              query: null,
              bodyJson: null,
            )!
            as Map<String, dynamic>;

    expect(body['token'], '');
  });
}
