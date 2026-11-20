import 'package:app/app/di.dart';
import 'package:app/features/permission_pre_prompt/permission_kind.dart';
import 'package:app/features/permission_pre_prompt/permission_pre_prompt_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_harness.dart';

// A single reusable no-op, so every brightness case below needs only one
// ignored empty block, not one per call site.
// ignore: solid_lints/no_empty_block
void _noop() {}

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  for (final brightness in Brightness.values) {
    testWidgets('renders in ${brightness.name} without throwing', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        PermissionPrePromptView(kind: PermissionKind.push, onContinue: _noop),
        brightness: brightness,
      );
      await tester.pumpAndSettle();

      expect(find.byType(PermissionPrePromptView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
