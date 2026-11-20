import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

import '../support/app_harness.dart';

/// Every spacing token paired with its vertical and horizontal gap.
final List<({SpaceToken token, Widget v, Widget h})> _gaps = [
  (token: space1, v: const AppGap.v1(), h: const AppGap.h1()),
  (token: space2, v: const AppGap.v2(), h: const AppGap.h2()),
  (token: space3, v: const AppGap.v3(), h: const AppGap.h3()),
  (token: space4, v: const AppGap.v4(), h: const AppGap.h4()),
  (token: space6, v: const AppGap.v6(), h: const AppGap.h6()),
  (token: space8, v: const AppGap.v8(), h: const AppGap.h8()),
  (token: space12, v: const AppGap.v12(), h: const AppGap.h12()),
  (token: space16, v: const AppGap.v16(), h: const AppGap.h16()),
  (token: space24, v: const AppGap.v24(), h: const AppGap.h24()),
];

/// Resolves [token] against the theme the pumped tree installs.
double _resolve(WidgetTester tester, SpaceToken token) {
  return token.resolve(tester.element(find.byType(AppGap)));
}

void main() {
  group('AppGap', () {
    for (final gap in _gaps) {
      testWidgets('${gap.token.name} vertical is token-high', (tester) async {
        await tester.pumpWidget(testApp(Column(children: [gap.v])));
        final expected = _resolve(tester, gap.token);

        final size = tester.getSize(find.byType(AppGap));
        expect(expected, greaterThan(0));
        expect(size.height, expected);
      });

      testWidgets('${gap.token.name} horizontal is token-wide', (tester) async {
        await tester.pumpWidget(testApp(Row(children: [gap.h])));
        final expected = _resolve(tester, gap.token);

        final size = tester.getSize(find.byType(AppGap));
        expect(size.width, expected);
      });
    }
  });
}
