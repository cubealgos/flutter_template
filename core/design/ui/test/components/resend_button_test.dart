import 'package:flutter_test/flutter_test.dart';
import 'package:ui/src/components/button.dart';
import 'package:ui/src/components/resend_button.dart';
import 'package:ui/src/components/text_link_button.dart';

import '../support/app_harness.dart';

// A single reusable no-op, so every "doesn't need a real callback" test
// case below needs only one ignored empty block, not one per call site.
// ignore: solid_lints/no_empty_block
void _noop() {}

/// An arbitrary cooldown value, used to prove the countdown label formats
/// as `0:28`, not `0:2:8` or similar.
const int _midCooldownSeconds = 28;

/// A cooldown past one minute, used to prove minutes/seconds both format
/// with a leading zero (`1:05`, not `1:5`).
const int _overOneMinuteSeconds = 65;

void main() {
  group('AppResendButton cooldown state', () {
    testWidgets('secondsRemaining: 0 renders an active link button', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(const AppResendButton(label: 'Resend code', onPressed: _noop)),
      );

      expect(find.byType(AppTextLinkButton), findsOneWidget);
      expect(find.byType(AppButton), findsNothing);
      expect(find.text('Resend code'), findsOneWidget);
    });

    testWidgets(
      'a positive secondsRemaining renders a disabled countdown button',
      (tester) async {
        var pressed = false;

        await tester.pumpWidget(
          testApp(
            AppResendButton(
              label: 'Resend code',
              secondsRemaining: _midCooldownSeconds,
              onPressed: () => pressed = true,
            ),
          ),
        );

        expect(find.byType(AppTextLinkButton), findsNothing);
        expect(find.text('Resend code · 0:28'), findsOneWidget);

        await tester.tap(find.byType(AppButton));
        await tester.pump();

        expect(pressed, isFalse);
      },
    );

    testWidgets('formats minutes and seconds with a leading zero', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          const AppResendButton(
            label: 'Resend code',
            secondsRemaining: _overOneMinuteSeconds,
            onPressed: _noop,
          ),
        ),
      );

      expect(find.text('Resend code · 1:05'), findsOneWidget);
    });
  });

  group('AppResendButton interaction', () {
    testWidgets('calls onPressed once the cooldown has elapsed', (
      tester,
    ) async {
      var pressed = false;

      await tester.pumpWidget(
        testApp(
          AppResendButton(
            label: 'Resend code',
            onPressed: () => pressed = true,
          ),
        ),
      );
      await tester.tap(find.byType(AppTextLinkButton));
      await tester.pump();

      expect(pressed, isTrue);
    });
  });
}
