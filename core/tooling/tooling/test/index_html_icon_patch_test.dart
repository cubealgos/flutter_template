import 'package:test/test.dart';
import 'package:tooling/src/index_html_icon_patch.dart';

/// A trimmed stand-in for `apps/app/web/index.html`'s `<head>` — just
/// enough to exercise the patch's anchor and pre-existing apple-touch-icon
/// tag, in the exact shape `flutter create` leaves it (confirmed against
/// flutter_launcher_icons' `lib/web/web_icon_generator.dart` source: it
/// never touches index.html, so this shape survives that tool untouched).
const String _sampleHead = '''
<head>
  <meta charset="UTF-8">

  <!-- iOS meta tags & icons -->
  <meta name="mobile-web-app-capable" content="yes">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">

  <!-- Favicon -->
  <link rel="icon" type="image/png" href="favicon.png"/>

  <title>app</title>
</head>
''';

void main() {
  test('inserts both canonical tags before the PNG favicon anchor', () {
    final patched = patchIndexHtmlIconTags(_sampleHead);

    expect(patched, contains(appleTouchIconLinkTag));
    expect(patched, contains(faviconIcoLinkTag));
    expect(
      patched.indexOf(appleTouchIconLinkTag),
      lessThan(patched.indexOf('type="image/png" href="favicon.png"')),
    );
  });

  test('replaces a pre-existing apple-touch-icon tag rather than '
      'duplicating it', () {
    final patched = patchIndexHtmlIconTags(_sampleHead);

    // `apple-touch-icon` alone would also match the new tag's own
    // `apple-touch-icon.png` href — count the `<link rel=` occurrence
    // instead to assert there's exactly one tag, not one substring.
    expect('<link rel="apple-touch-icon"'.allMatches(patched).length, 1);
    expect(patched, isNot(contains('icons/Icon-192.png')));
  });

  test('running twice changes nothing further (idempotent)', () {
    final firstPass = patchIndexHtmlIconTags(_sampleHead);
    final secondPass = patchIndexHtmlIconTags(firstPass);

    expect(secondPass, firstPass);
  });

  test('running on an already-clean template (no apple-touch-icon tag '
      'yet) still inserts both tags exactly once', () {
    const noAppleTouchIcon = '''
<head>
  <link rel="icon" type="image/png" href="favicon.png"/>
  <title>app</title>
</head>
''';

    final patched = patchIndexHtmlIconTags(noAppleTouchIcon);

    expect('<link rel="apple-touch-icon"'.allMatches(patched).length, 1);
    expect('favicon.ico'.allMatches(patched).length, 1);
  });

  test('throws a FormatException when the PNG favicon anchor is missing', () {
    expect(
      () => patchIndexHtmlIconTags('<head><title>app</title></head>'),
      throwsFormatException,
    );
  });

  group('normalizeIndexHtmlBlankLines', () {
    test('strips trailing whitespace from every line', () {
      const withTrailingWhitespace = 'line one   \nline two\t\nline three';

      expect(
        normalizeIndexHtmlBlankLines(withTrailingWhitespace),
        'line one\nline two\nline three',
      );
    });

    test('collapses a run of blank (or whitespace-only) lines to one', () {
      const withStrayBlankLines = 'a\n\n  \n   \n\nb';

      expect(normalizeIndexHtmlBlankLines(withStrayBlankLines), 'a\n\nb');
    });

    test('running twice changes nothing further (idempotent)', () {
      const messy = 'a\n\n  \nb   \n\n\n\nc';

      final firstPass = normalizeIndexHtmlBlankLines(messy);
      final secondPass = normalizeIndexHtmlBlankLines(firstPass);

      expect(secondPass, firstPass);
    });

    test('leaves already-clean content untouched', () {
      const clean = '<head>\n  <title>app</title>\n</head>\n';

      expect(normalizeIndexHtmlBlankLines(clean), clean);
    });
  });
}
