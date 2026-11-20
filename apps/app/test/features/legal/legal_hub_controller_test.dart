import 'package:app/app/config.dart';
import 'package:app/app/router.dart';
import 'package:app/features/legal/legal_hub_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mvc/mvc.dart';

import 'legal_hub_controller_test.mocks.dart';

@GenerateNiceMocks(<MockSpec<Object>>[MockSpec<NavigationService>()])
void main() {
  group('LegalHubController', () {
    test('showAccessibilityStatement mirrors AppConfig', () {
      final on = LegalHubController(
        MockNavigationService(),
        const AppConfig(accessibilityStatement: true),
      );
      final off = LegalHubController(
        MockNavigationService(),
        const AppConfig(),
      );

      expect(on.model.showAccessibilityStatement, isTrue);
      expect(off.model.showAccessibilityStatement, isFalse);
    });

    test('each open* method pushes its route', () {
      final navigation = MockNavigationService();
      LegalHubController(navigation, const AppConfig())
        ..openImpressum()
        ..openDatenschutz()
        ..openAgb()
        ..openBarrierefreiheit()
        ..openLicences();

      verify(navigation.push(const ImpressumRoute().location)).called(1);
      verify(navigation.push(const DatenschutzRoute().location)).called(1);
      verify(navigation.push(const AgbRoute().location)).called(1);
      verify(navigation.push(const BarrierefreiheitRoute().location)).called(1);
      verify(navigation.push(const LicencesRoute().location)).called(1);
    });
  });
}
