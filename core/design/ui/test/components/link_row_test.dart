import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/src/components/link_row.dart';
import 'package:ui/src/components/text_link_button.dart';

import '../support/app_harness.dart';

// A no-op callback; nothing is asserted on it.
// ignore: solid_lints/no_empty_block
void _noop() {}

/// Wide enough for all three links on one line.
const double _rowWidth = 600;

const _labels = <String>['Legal', 'Terms & Conditions', 'Privacy Policy'];

void main() {
  testWidgets('separates n links with n-1 dots, all on one line', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: _rowWidth,
            child: AppLinkRow(
              links: <AppTextLinkButton>[
                for (final label in _labels)
                  AppTextLinkButton(label: label, onPressed: _noop),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('·'), findsNWidgets(_labels.length - 1));

    final lineCentres = {
      for (final label in _labels) tester.getCenter(find.text(label)).dy,
      tester.getCenter(find.text('·').first).dy,
    };
    expect(lineCentres, hasLength(1));
  });
}
