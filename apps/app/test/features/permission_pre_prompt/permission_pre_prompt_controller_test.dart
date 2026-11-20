import 'package:app/features/permission_pre_prompt/permission_kind.dart';
import 'package:app/features/permission_pre_prompt/permission_pre_prompt_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mvc/mvc.dart';

import 'permission_pre_prompt_controller_test.mocks.dart';

// A no-op used where a test needs a callback but never asserts it ran.
// ignore: solid_lints/no_empty_block
void _doNothing() {}

@GenerateNiceMocks(<MockSpec<Object>>[MockSpec<DialogService>()])
void main() {
  group('PermissionPrePromptController', () {
    test('continuePressed runs onContinue then closes with true', () {
      final dialogService = MockDialogService();
      var continued = false;
      PermissionPrePromptController(
        dialogService,
        kind: PermissionKind.push,
        onContinue: () => continued = true,
      ).continuePressed();

      expect(continued, isTrue);
      verify(dialogService.close(true)).called(1);
    });

    test('notNowPressed closes with false without running onContinue', () {
      final dialogService = MockDialogService();
      var continued = false;
      PermissionPrePromptController(
        dialogService,
        kind: PermissionKind.att,
        onContinue: () => continued = true,
      ).notNowPressed();

      expect(continued, isFalse);
      verify(dialogService.close(false)).called(1);
    });

    test('model carries the requested kind', () {
      final controller = PermissionPrePromptController(
        MockDialogService(),
        kind: PermissionKind.location,
        onContinue: _doNothing,
      );

      expect(controller.model.kind, PermissionKind.location);
    });
  });
}
