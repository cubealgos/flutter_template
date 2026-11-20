import 'package:app/app/preference_keys.dart';
import 'package:app/features/settings/privacy/consent_status.dart';
import 'package:app/features/settings/privacy/export_error.dart';
import 'package:app/features/settings/privacy/export_phase.dart';
import 'package:app/features/settings/privacy/privacy_settings_controller.dart';
import 'package:auth/auth.dart';
import 'package:data/data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mvc/mvc.dart';

import '../../../support/settle.dart';
import 'privacy_settings_controller_test.mocks.dart';

@GenerateNiceMocks(<MockSpec<Object>>[
  MockSpec<NavigationService>(),
  MockSpec<ClipboardService>(),
])
void main() {
  group('PrivacySettingsController consent', () {
    test('starts as notSet, then reflects a stored choice', () async {
      final preferences = FakeUserPreferences();
      await preferences.update(<String, dynamic>{
        consentAcceptedPreferenceKey: true,
      });
      final controller = PrivacySettingsController(
        MockNavigationService(),
        preferences,
        FakeAuthService(),
        FakeDocumentRepository(),
        MockClipboardService(),
      )..init();

      await settle();

      expect(controller.model.consentStatus, ConsentStatus.accepted);
    });

    test('setConsent withdraws/changes the choice, same key ConsentController '
        'writes', () async {
      final preferences = FakeUserPreferences();
      final controller = PrivacySettingsController(
        MockNavigationService(),
        preferences,
        FakeAuthService(),
        FakeDocumentRepository(),
        MockClipboardService(),
      );

      await controller.setConsent(accepted: false);

      expect(controller.model.consentStatus, ConsentStatus.rejected);
      expect(
        (await preferences.getAll())[consentAcceptedPreferenceKey],
        isFalse,
      );
    });
  });

  group('PrivacySettingsController export with step-up', () {
    test(
      'startExport fails with noEmail for a session without an email',
      () async {
        final auth = FakeAuthService();
        await auth.signInWithPasskey();
        final controller = PrivacySettingsController(
          MockNavigationService(),
          FakeUserPreferences(),
          auth,
          FakeDocumentRepository(),
          MockClipboardService(),
        );

        await controller.startExport();

        expect(controller.model.exportError, ExportError.noEmail);
        expect(controller.model.exportPhase, ExportPhase.idle);
      },
    );

    test(
      'startExport moves to the stepUp phase for an email session',
      () async {
        final auth = FakeAuthService();
        final request = await auth.requestEmailCode('a@b.c');
        await auth.verifyEmailCode(request, FakeAuthService.fixedEmailCode);
        final controller = PrivacySettingsController(
          MockNavigationService(),
          FakeUserPreferences(),
          auth,
          FakeDocumentRepository(),
          MockClipboardService(),
        );

        await controller.startExport();

        expect(controller.model.exportPhase, ExportPhase.stepUp);
      },
    );
  });

  group('PrivacySettingsController verifying the step-up code', () {
    test(
      "a correct step-up code exports the user's documents as JSON",
      () async {
        final auth = FakeAuthService();
        final request = await auth.requestEmailCode('a@b.c');
        await auth.verifyEmailCode(request, FakeAuthService.fixedEmailCode);
        final documents = FakeDocumentRepository();
        await documents.create(<String, dynamic>{
          'displayName': 'Ada',
        }, id: 'doc1');
        final controller = PrivacySettingsController(
          MockNavigationService(),
          FakeUserPreferences(),
          auth,
          documents,
          MockClipboardService(),
        );
        await controller.startExport();

        await controller.verifyStepUpAndExport(FakeAuthService.fixedEmailCode);

        expect(controller.model.exportPhase, ExportPhase.result);
        expect(controller.model.exportedJson, contains('Ada'));
        expect(controller.model.exportedJson, contains('doc1'));
      },
    );

    test('a wrong step-up code sets ExportError.invalidCode and does not '
        'export', () async {
      final auth = FakeAuthService();
      final request = await auth.requestEmailCode('a@b.c');
      await auth.verifyEmailCode(request, FakeAuthService.fixedEmailCode);
      final controller = PrivacySettingsController(
        MockNavigationService(),
        FakeUserPreferences(),
        auth,
        FakeDocumentRepository(),
        MockClipboardService(),
      );
      await controller.startExport();

      await controller.verifyStepUpAndExport('000000');

      expect(controller.model.exportError, ExportError.invalidCode);
      expect(controller.model.exportedJson, isNull);
    });
  });

  group('PrivacySettingsController copyExportedJson', () {
    test(
      'copies the exported JSON via the injected ClipboardService',
      () async {
        final auth = FakeAuthService();
        final request = await auth.requestEmailCode('a@b.c');
        await auth.verifyEmailCode(request, FakeAuthService.fixedEmailCode);
        final documents = FakeDocumentRepository();
        await documents.create(<String, dynamic>{
          'displayName': 'Ada',
        }, id: 'doc1');
        final clipboard = MockClipboardService();
        final controller = PrivacySettingsController(
          MockNavigationService(),
          FakeUserPreferences(),
          auth,
          documents,
          clipboard,
        );
        await controller.startExport();
        await controller.verifyStepUpAndExport(FakeAuthService.fixedEmailCode);
        final exportedJson = controller.model.exportedJson;
        expect(exportedJson, isNotNull);

        await controller.copyExportedJson();

        verify(clipboard.copyText(exportedJson ?? '')).called(1);
      },
    );

    test('is a no-op before the export result is available', () async {
      final clipboard = MockClipboardService();
      final controller = PrivacySettingsController(
        MockNavigationService(),
        FakeUserPreferences(),
        FakeAuthService(),
        FakeDocumentRepository(),
        clipboard,
      );

      await controller.copyExportedJson();

      verifyNever(clipboard.copyText(any));
    });
  });
}
