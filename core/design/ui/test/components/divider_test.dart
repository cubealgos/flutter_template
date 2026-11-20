import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/src/components/divider.dart';

import '../support/app_harness.dart';

/// An arbitrary width, just wide enough to show the divider stretches to
/// fill its parent rather than collapsing to zero.
const double _parentWidth = 200;

/// The hairline's expected thickness — `stroke.thin`'s 1px.
const double _expectedThickness = 1;

void main() {
  group('AppDivider', () {
    testWidgets('renders a thin, full-width hairline', (tester) async {
      await tester.pumpWidget(
        testApp(
          const Center(
            child: SizedBox(width: _parentWidth, child: AppDivider()),
          ),
        ),
      );

      final size = tester.getSize(find.byType(AppDivider));
      expect(size.width, _parentWidth);
      expect(size.height, _expectedThickness);
    });
  });
}
