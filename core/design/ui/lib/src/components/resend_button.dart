import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/src/components/button.dart';
import 'package:ui/src/components/text_link_button.dart';
import 'package:ui/src/tokens.g.dart';
import 'package:ui/src/typography/text_styles.dart';

/// Pads a single-digit seconds value with a leading zero — `0:05`, not
/// `0:5`, matching the mockups' `Resend code · 0:28`.
const int _secondsPerMinute = 60;

/// How many digits the seconds portion of the countdown is padded to.
const int _secondsDigitWidth = 2;

/// A resend-code affordance with a built-in cooldown: a disabled button
/// showing a live countdown while [secondsRemaining] is positive, or a
/// tappable underlined link once it reaches zero (spec.md §2.3's "Resend
/// code" control; `tokens-needed.md` §B flags this as missing entirely —
/// neither a visual treatment nor a controller-level cooldown concept
/// existed before this component).
///
// This file is named for the component's role; the class carries this
// package's `App` prefix, so the two names don't literally match — same
// convention as core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class AppResendButton extends StatelessWidget {
  /// Creates an `AppResendButton`.
  const AppResendButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.secondsRemaining = 0,
  });

  /// The button's base label, e.g. "Resend code" — already localized by
  /// the caller (this package owns no strings/i18n).
  final String label;

  /// Seconds left in the cooldown. `0` (the default) renders an active,
  /// tappable link; a positive value renders a disabled countdown instead.
  final int secondsRemaining;

  /// Called when the resend link is activated. Never called while
  /// [secondsRemaining] is positive, since the button renders disabled.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final remaining = secondsRemaining;
    if (remaining <= 0) {
      return AppTextLinkButton(label: label, onPressed: onPressed);
    }

    final minutes = remaining ~/ _secondsPerMinute;
    final seconds = (remaining % _secondsPerMinute).toString().padLeft(
      _secondsDigitWidth,
      '0',
    );
    final countdownLabel = '$label · $minutes:$seconds';

    return AppButton(
      semanticLabel: countdownLabel,
      onPressed: null,
      disabled: true,
      variant: AppButtonVariant.secondary,
      child: StyledText(countdownLabel, style: buttonStyle().color(colorFg())),
    );
  }
}
