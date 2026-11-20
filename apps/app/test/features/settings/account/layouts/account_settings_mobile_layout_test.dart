import 'package:app/features/settings/account/account_settings_model.dart';
import 'package:app/features/settings/account/layouts/account_settings_mobile_layout.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/layout_harness.dart';

void main() {
  testWidgets('AccountSettingsMobileLayout shows the sections and forwards '
      'the delete tap', (tester) async {
    var deleted = false;
    await pumpLayout(
      tester,
      AccountSettingsMobileLayout(
        model: const AccountSettingsModel(loading: false),
        onBack: noop,
        onDisconnect: noop,
        onDeleteAccount: () => deleted = true,
      ),
      width: mobileWidth,
    );

    expect(find.text(t.settings.account.linkedIdentitiesTitle), findsOneWidget);
    await tester.tap(find.text(t.settings.account.deleteAccountButton));
    expect(deleted, isTrue);
  });
}
