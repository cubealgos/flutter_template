import 'package:app/features/legal/licences/licences_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mvc/mvc.dart';

import '../../../support/settle.dart';
import 'licences_controller_test.mocks.dart';

/// The number of distinct package names the grouping test's fixture
/// stream produces, once `abseil-cpp`'s two entries collapse into one row.
const int _groupedEntryCount = 2;

@GenerateNiceMocks(<MockSpec<Object>>[
  MockSpec<NavigationService>(),
  MockSpec<ClipboardService>(),
])
void main() {
  group('LicencesController collection', () {
    test('collects every licence from the injected stream', () async {
      const entryCount = 2;
      final licenses = Stream<LicenseEntry>.fromIterable(<LicenseEntry>[
        const LicenseEntryWithLineBreaks(<String>['pkg_a'], 'MIT License text'),
        const LicenseEntryWithLineBreaks(<String>['pkg_b'], 'BSD License text'),
      ]);
      final controller = LicencesController(
        MockNavigationService(),
        MockClipboardService(),
        licenses: licenses,
      )..init();

      await settle();

      expect(controller.model.loading, isFalse);
      expect(controller.model.entries, hasLength(entryCount));
      expect(controller.model.entries.first.packageName, 'pkg_a');
      expect(controller.model.entries.first.texts, <String>[
        'MIT License text',
      ]);
    });

    test('an empty stream ends with no entries, not stuck loading', () async {
      final controller = LicencesController(
        MockNavigationService(),
        MockClipboardService(),
        licenses: const Stream<LicenseEntry>.empty(),
      )..init();

      await settle();

      expect(controller.model.loading, isFalse);
      expect(controller.model.entries, isEmpty);
    });
  });

  group('LicencesController grouping by package name', () {
    test('groups by package name — a package named by more than one entry '
        'collects every text under one row, alphabetically sorted', () async {
      final licenses = Stream<LicenseEntry>.fromIterable(<LicenseEntry>[
        const LicenseEntryWithLineBreaks(<String>['zebra'], 'Zebra text'),
        const LicenseEntryWithLineBreaks(<String>[
          'abseil-cpp',
        ], 'Abseil text 1'),
        const LicenseEntryWithLineBreaks(<String>[
          'abseil-cpp',
        ], 'Abseil text 2'),
      ]);
      final controller = LicencesController(
        MockNavigationService(),
        MockClipboardService(),
        licenses: licenses,
      )..init();

      await settle();

      final [abseil, zebra] = controller.model.entries;

      expect(controller.model.entries, hasLength(_groupedEntryCount));
      expect(abseil.packageName, 'abseil-cpp');
      expect(abseil.texts, <String>['Abseil text 1', 'Abseil text 2']);
      expect(zebra.packageName, 'zebra');
      expect(zebra.texts, <String>['Zebra text']);
    });
  });

  group('LicencesController navigation and clipboard', () {
    test('goBack pops when there is somewhere to pop back to', () {
      final navigation = MockNavigationService();
      when(navigation.canPop()).thenReturn(true);
      LicencesController(
        navigation,
        MockClipboardService(),
        licenses: const Stream<LicenseEntry>.empty(),
      ).goBack();

      verify(navigation.pop()).called(1);
    });

    test('copyLicenceText copies via the injected ClipboardService', () async {
      final clipboard = MockClipboardService();
      final controller = LicencesController(
        MockNavigationService(),
        clipboard,
        licenses: const Stream<LicenseEntry>.empty(),
      );

      await controller.copyLicenceText('MIT License text');

      verify(clipboard.copyText('MIT License text')).called(1);
    });
  });
}
