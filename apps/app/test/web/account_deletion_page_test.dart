import 'dart:io';

import 'package:app/app/config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  test('the static account-deletion page (shipped with the web build, for '
      "Google Play's account-deletion requirement) quotes AppConfig's own "
      'placeholder contact — kept in sync by hand, checked here so a drift '
      'between the two fails a test instead of shipping quietly', () {
    final pageFile = File(
      path.join(
        Directory.current.path,
        'web',
        'account-deletion',
        'index.html',
      ),
    );

    expect(
      pageFile.existsSync(),
      isTrue,
      reason: 'expected ${pageFile.path} to exist',
    );

    final html = pageFile.readAsStringSync();
    const config = AppConfig();

    expect(
      html,
      contains(config.legalContactEmail),
      reason:
          'apps/app/web/account-deletion/index.html should quote the '
          'same contact address as AppConfig.legalContactEmail '
          '(currently "${config.legalContactEmail}") — update both '
          'together.',
    );
  });
}
