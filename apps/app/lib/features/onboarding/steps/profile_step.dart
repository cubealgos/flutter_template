import 'package:app/features/onboarding/onboarding_step.dart';
import 'package:app/features/onboarding/steps/onboarding_saved_hint.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// The template's default first step: an avatar placeholder (no image
/// picker dependency — "Add photo" is a documented no-op, same convention
/// as `HomeController`'s push-permission callback) plus a display name
/// field. The whole step's answer is that name, a plain `String`.
OnboardingStep profileOnboardingStep() {
  return OnboardingStep(
    id: 'profile',
    title: t.onboarding.stepProfileTitle,
    builder: (_, scope) => _ProfileStepBody(scope: scope),
  );
}

// This file is named for the step it defines; the top-level
// `profileOnboardingStep()` factory (not a class) is this file's real
// public surface, so its first class — a private body widget — doesn't
// literally match the file name. Same convention as
// `core/design/ui/lib/src/components/*.dart`.
// ignore: solid_lints/prefer_match_file_name
class _ProfileStepBody extends StatefulWidget {
  const _ProfileStepBody({required this.scope});

  final OnboardingStepScope scope;

  @override
  State<_ProfileStepBody> createState() => _ProfileStepBodyState();
}

class _ProfileStepBodyState extends State<_ProfileStepBody> {
  // Seeded once from the persisted answer at resume time — deliberately not
  // kept in sync with `widget.scope.answer` on every rebuild, so typing
  // doesn't fight the cursor position with the value this same widget just
  // reported back up (see `OnboardingController.updateAnswer`).
  // ignore: solid_lints/avoid_late_keyword
  late final TextEditingController _nameController = TextEditingController(
    text: widget.scope.answer as String? ?? '',
  );

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saved = (widget.scope.answer as String? ?? '').isNotEmpty;

    return Column(
      children: [
        const _AvatarPicker(),
        const AppGap.v6(),
        AppTextField(
          label: t.onboarding.stepProfileDisplayNameLabel,
          controller: _nameController,
          onChanged: widget.scope.onChanged,
        ),
        const AppGap.v3(),
        OnboardingSavedHint(visible: saved),
      ],
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker();

  // The mockup's `+` glyph, hand-painted (see `_PlusPainter`) rather than
  // a plain text character — matches `core/design/ui`'s own
  // no-icon-font convention (`AppChevronIcon`'s dartdoc) more closely
  // than a "+" glyph would. `ui` has no generic add/plus icon to reuse,
  // so this stays app-local rather than adding an icon package.
  static const double _glyphSize = 24;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Box(
          // 96×96 — exactly `space24`, even though this is a component
          // frame rather than a spacing gap.
          style: BoxStyler()
              .size(space24(), space24())
              .color(colorSurface())
              .borderAll(color: colorBorder(), width: strokeThin()),
          child: Center(
            child: CustomPaint(
              size: const Size(_glyphSize, _glyphSize),
              painter: _PlusPainter(color: colorFgSubtle.resolve(context)),
            ),
          ),
        ),
        const AppGap.v3(),
        AppButton(
          semanticLabel: t.onboarding.stepProfileAddPhotoButton,
          variant: AppButtonVariant.secondary,
          // A real app wires this to an image picker; this template adds
          // no such dependency — same convention as `HomeController`'s
          // push-permission `onContinue`.
          // ignore: solid_lints/no_empty_block
          onPressed: () {},
          child: Text(t.onboarding.stepProfileAddPhotoButton),
        ),
      ],
    );
  }
}

/// A simple plus glyph, painted without any icon-font or Material
/// dependency (matches `AppChevronIcon`'s own approach) — mirrors the
/// mockups' inline SVG two-line cross (24×24 viewBox, one vertical and
/// one horizontal stroke, each centered).
class _PlusPainter extends CustomPainter {
  const _PlusPainter({required this.color});

  static const double _viewBoxSize = 24;
  static const double _strokeWidth = 1.5;

  /// The vertical stroke's shared x-coordinate, and the horizontal
  /// stroke's shared y-coordinate — both centered in the 24×24 viewBox.
  static const double _center = 12;

  /// Both strokes' near edge, in the 24×24 viewBox.
  static const double _edgeStart = 5;

  /// Both strokes' far edge — the mirror of [_edgeStart].
  static const double _edgeEnd = 19;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    final scale = size.width / _viewBoxSize;

    canvas
      ..drawLine(
        Offset(_center * scale, _edgeStart * scale),
        Offset(_center * scale, _edgeEnd * scale),
        paint,
      )
      ..drawLine(
        Offset(_edgeStart * scale, _center * scale),
        Offset(_edgeEnd * scale, _center * scale),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant _PlusPainter oldDelegate) =>
      oldDelegate.color != color;
}
