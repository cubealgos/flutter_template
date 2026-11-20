import 'package:app/features/legal/document/legal_document_controller.dart';
import 'package:app/features/legal/document/legal_document_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mvc/mvc.dart';

import 'legal_document_controller_test.mocks.dart';

@GenerateNiceMocks(<MockSpec<Object>>[MockSpec<NavigationService>()])
void main() {
  group('LegalDocumentController', () {
    test('model carries the requested document type', () {
      final controller = LegalDocumentController(
        MockNavigationService(),
        type: LegalDocumentType.datenschutz,
      );

      expect(controller.model.type, LegalDocumentType.datenschutz);
    });

    test('goBack pops when there is somewhere to pop back to', () {
      final navigation = MockNavigationService();
      when(navigation.canPop()).thenReturn(true);
      LegalDocumentController(
        navigation,
        type: LegalDocumentType.impressum,
      ).goBack();

      verify(navigation.pop()).called(1);
    });

    test('goBack does nothing when there is nothing to pop back to', () {
      final navigation = MockNavigationService();
      when(navigation.canPop()).thenReturn(false);
      LegalDocumentController(
        navigation,
        type: LegalDocumentType.impressum,
      ).goBack();

      verifyNever(navigation.pop());
    });
  });
}
