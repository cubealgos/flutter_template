import 'package:app/features/legal/licences/layouts/licences_mobile_layout.dart';
import 'package:app/features/legal/licences/licence_group.dart';
import 'package:app/features/legal/licences/licences_model.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/layout_harness.dart';

void main() {
  testWidgets('LicencesMobileLayout lists packages and copies a licence text '
      'from its detail sheet', (tester) async {
    String? copied;
    await pumpLayout(
      tester,
      // `showAppSheet` needs a `Navigator` (and its `Overlay`) above it.
      Navigator(
        onGenerateRoute: (_) => PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => LicencesMobileLayout(
            model: const LicencesModel(
              loading: false,
              entries: [
                LicenceGroup(packageName: 'demo_pkg', texts: ['MIT text']),
              ],
            ),
            onBack: noop,
            onCopyLicenceText: (text) => copied = text,
          ),
        ),
      ),
      width: mobileWidth,
    );

    await tester.tap(find.text('demo_pkg'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.legal.licences.copyButton));

    expect(copied, 'MIT text');
  });
}
