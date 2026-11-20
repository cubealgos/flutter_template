import 'package:app/features/permission_pre_prompt/layouts/permission_pre_prompt_mobile_layout.dart';
import 'package:app/features/permission_pre_prompt/permission_kind.dart';
import 'package:app/features/permission_pre_prompt/permission_pre_prompt_model.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/layout_harness.dart';

void main() {
  testWidgets('PermissionPrePromptMobileLayout shows the push copy and '
      'forwards both taps', (tester) async {
    var notNow = false;
    var continued = false;
    await pumpLayout(
      tester,
      PermissionPrePromptMobileLayout(
        model: const PermissionPrePromptModel(kind: PermissionKind.push),
        onNotNow: () => notNow = true,
        onContinue: () => continued = true,
      ),
      width: mobileWidth,
    );

    expect(find.text(t.permissionPrePrompt.pushTitle), findsOneWidget);
    await tester.tap(find.text(t.common.notNow));
    await tester.tap(find.text(t.common.continueLabel));

    expect(notNow, isTrue);
    expect(continued, isTrue);
  });
}
