import 'dart:math' as math;

import 'package:app/app/preference_keys.dart';
import 'package:app/features/onboarding/onboarding_step.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// The template's default third step: reuses the existing permission
/// pre-prompt copy (`t.permissionPrePrompt.pushMessage` — see
/// `lib/features/permission_pre_prompt/`), shown in context inside the
/// stepper rather than as a system-styled dialog. Has no answer of its own
/// — only a completed/skipped status — and marks the separate
/// `HomeController` push pre-prompt as already shown via `onFinished`, so
/// a user who has just seen this framing here isn't asked again on Home.
OnboardingStep notificationsOnboardingStep() {
  return OnboardingStep(
    id: 'notifications',
    title: t.onboarding.stepNotificationsTitle,
    skip: OnboardingSkipAffordance.bottomButton,
    builder: (_, _) => const _NotificationsStepBody(),
    onFinished: (preferences) => preferences.update(<String, dynamic>{
      pushPermissionPromptShownPreferenceKey: true,
    }),
  );
}

// This file is named for the step it defines; the top-level
// `notificationsOnboardingStep()` factory (not a class) is this file's real
// public surface, so its first class — a private body widget — doesn't
// literally match the file name. Same convention as
// `core/design/ui/lib/src/components/*.dart`.
// ignore: solid_lints/prefer_match_file_name
class _NotificationsStepBody extends StatelessWidget {
  const _NotificationsStepBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _BellIcon(),
        const AppGap.v4(),
        StyledText(
          t.permissionPrePrompt.pushMessage,
          style: bodyStyle().textAlign(TextAlign.center),
        ),
      ],
    );
  }
}

class _BellIcon extends StatelessWidget {
  const _BellIcon();

  static const double _size = 32;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(_size, _size),
      painter: _BellPainter(color: colorLink.resolve(context)),
    );
  }
}

/// [_BellPainter]'s stroke width, in logical pixels.
const double _bellStrokeWidth = 1.5;

/// The bell body's left/right edge, as a fraction of the painter's width.
const double _bellSideX = 0.22;

/// The mirror of [_bellSideX] (the body's right edge).
const double _bellSideXMirror = 0.78;

/// Where the body's straight sides start curving inward, as a fraction of
/// width — the bell's "shoulder".
const double _bellShoulderX = 0.31;

/// The mirror of [_bellShoulderX].
const double _bellShoulderXMirror = 0.69;

/// The dome's horizontal center, as a fraction of width.
const double _bellCenterX = 0.5;

/// The body's bottom edge, as a fraction of the painter's height.
const double _bellBottomY = 0.72;

/// The shoulder's height, as a fraction of the painter's height.
const double _bellShoulderY = 0.55;

/// Where the shoulder's curve meets the dome, as a fraction of height.
const double _bellDomeBaseY = 0.34;

/// The dome's own curve control height, as a fraction of height.
const double _bellDomeMidY = 0.16;

/// The dome's topmost point, as a fraction of height.
const double _bellDomeTopY = 0.06;

/// The dome curve's own control point, just inside [_bellCenterX].
const double _bellDomeShoulderX = 0.42;

/// The mirror of [_bellDomeShoulderX].
const double _bellDomeShoulderXMirror = 0.58;

/// The clapper arc's vertical center, as a fraction of height.
const double _clapperCenterY = 0.78;

/// The clapper arc's width, as a fraction of the painter's width.
const double _clapperWidthFraction = 0.28;

/// The clapper arc's height, as a fraction of the painter's height.
const double _clapperHeightFraction = 0.24;

/// A simple hand-drawn bell glyph, painted without any icon-font or
/// Material dependency (matches `AppChevronIcon`'s own approach) — an
/// approximation of the mockups' bell SVG, not a pixel-exact trace.
class _BellPainter extends CustomPainter {
  const _BellPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _bellStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas
      ..drawPath(_bodyPath(size), paint)
      ..drawArc(_clapperRect(size), 0, math.pi, false, paint);
  }

  /// The bell's dome-and-shoulders outline, scaled to [size].
  Path _bodyPath(Size size) {
    final w = size.width;
    final h = size.height;

    return Path()
      ..moveTo(w * _bellSideXMirror, h * _bellBottomY)
      ..lineTo(w * _bellSideX, h * _bellBottomY)
      ..cubicTo(
        w * _bellSideX,
        h * _bellBottomY,
        w * _bellShoulderX,
        h * _bellShoulderY,
        w * _bellShoulderX,
        h * _bellDomeBaseY,
      )
      ..cubicTo(
        w * _bellShoulderX,
        h * _bellDomeMidY,
        w * _bellDomeShoulderX,
        h * _bellDomeTopY,
        w * _bellCenterX,
        h * _bellDomeTopY,
      )
      ..cubicTo(
        w * _bellDomeShoulderXMirror,
        h * _bellDomeTopY,
        w * _bellShoulderXMirror,
        h * _bellDomeMidY,
        w * _bellShoulderXMirror,
        h * _bellDomeBaseY,
      )
      ..cubicTo(
        w * _bellShoulderXMirror,
        h * _bellShoulderY,
        w * _bellSideXMirror,
        h * _bellBottomY,
        w * _bellSideXMirror,
        h * _bellBottomY,
      )
      ..close();
  }

  /// The clapper arc's bounding box, scaled to [size].
  Rect _clapperRect(Size size) {
    return Rect.fromCenter(
      center: Offset(size.width * _bellCenterX, size.height * _clapperCenterY),
      width: size.width * _clapperWidthFraction,
      height: size.height * _clapperHeightFraction,
    );
  }

  @override
  bool shouldRepaint(covariant _BellPainter oldDelegate) =>
      oldDelegate.color != color;
}
