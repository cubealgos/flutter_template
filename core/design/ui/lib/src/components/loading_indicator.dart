import 'package:flutter/widgets.dart';
import 'package:ui/src/components/internal/spinner.dart';
import 'package:ui/src/tokens.g.dart';

/// The indicator's default fixed square size, in logical pixels — larger
/// than `AppButton`'s own inline spinner (16px), since this renders as the
/// sole content of a screen region rather than inside a button.
const double _defaultDiameter = 24;

/// A standalone loading indicator for a screen region that has no other
/// visible content while it loads — Licences and Account Settings both
/// model a `loading` field with nothing rendered for it today (spec.md §3,
/// Pattern E), leaving a blank area rather than any visible feedback.
///
/// Shares its rotating-arc painter with `AppButton`'s built-in loading
/// state via the internal `Spinner` widget.
///
// This file is named for the component's role; the class carries this
// package's `App` prefix, so the two names don't literally match — same
// convention as core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class AppLoadingIndicator extends StatelessWidget {
  /// Creates an `AppLoadingIndicator`.
  const AppLoadingIndicator({super.key, this.diameter = _defaultDiameter});

  /// The indicator's fixed square size, in logical pixels.
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Spinner(
      color: colorAccent.resolve(context),
      period: motionDurationStep.resolve(context),
      diameter: diameter,
    );
  }
}
