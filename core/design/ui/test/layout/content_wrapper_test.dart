import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/src/layout/content_wrapper.dart';

import '../support/app_harness.dart';

/// Wider than every preset, so a child this size is always the one being
/// constrained down, never the other way around.
const double _widerThanEveryPreset = 2000;

/// Narrower than every preset, so a child this size is never stretched.
const double _narrowerThanEveryPreset = 100;

/// An arbitrary parent width, wider than [AppContentWidth.wide]'s own
/// preset, so [AppFullWidthButton] stretching to it is a meaningful check.
const double _parentWidth = 300;

/// A fixed, arbitrary height for the sizing probes below — irrelevant to
/// what each test actually checks (width), but [SizedBox] requires one.
const double _probeHeight = 10;

/// spec.md §1.1's auth/dialog max-width preset.
const double _authWidth = 440;

/// spec.md §1.1's settings/list max-width preset.
const double _listWidth = 640;

/// spec.md §1.1's long-text/legal reading-measure preset.
const double _readingWidth = 576;

/// spec.md §1.1's home/dashboard max-width preset.
const double _wideWidth = 960;

void main() {
  group('AppContentWidth presets', () {
    test("match spec.md §1.1's max-width table", () {
      expect(AppContentWidth.auth.maxWidth, _authWidth);
      expect(AppContentWidth.list.maxWidth, _listWidth);
      expect(AppContentWidth.reading.maxWidth, _readingWidth);
      expect(AppContentWidth.wide.maxWidth, _wideWidth);
    });
  });

  group('AppContentWrapper', () {
    testWidgets('constrains a wider child down to the preset max width', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          const Center(
            child: SizedBox(
              width: _widerThanEveryPreset,
              child: AppContentWrapper(
                width: AppContentWidth.auth,
                child: SizedBox(
                  width: _widerThanEveryPreset,
                  height: _probeHeight,
                  key: Key('child'),
                ),
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byKey(const Key('child')));
      expect(size.width, AppContentWidth.auth.maxWidth);
    });

    testWidgets('does not stretch a narrower child beyond its own width', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          const Center(
            child: AppContentWrapper(
              width: AppContentWidth.wide,
              child: SizedBox(
                width: _narrowerThanEveryPreset,
                height: _probeHeight,
                key: Key('child'),
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byKey(const Key('child')));
      expect(size.width, _narrowerThanEveryPreset);
    });
  });

  group('AppFullWidthButton', () {
    testWidgets('stretches its child to the available width', (tester) async {
      await tester.pumpWidget(
        testApp(
          const Center(
            child: SizedBox(
              width: _parentWidth,
              child: AppFullWidthButton(
                child: SizedBox(
                  width: _narrowerThanEveryPreset,
                  height: _probeHeight,
                  key: Key('child'),
                ),
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byKey(const Key('child')));
      expect(size.width, _parentWidth);
    });
  });
}
