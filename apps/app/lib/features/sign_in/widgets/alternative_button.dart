import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// One secondary sign-in button (passkey/Apple/Google/reviewer),
/// each rendered identically below the primary email flow.
class AlternativeButton extends StatelessWidget {
  /// Creates the button.
  const AlternativeButton({
    required this.semanticLabel,
    required this.onPressed,
    required this.label,
    super.key,
  });

  /// The accessibility label announced for the button.
  final String semanticLabel;

  /// Called when the button is pressed.
  final VoidCallback onPressed;

  /// The visible button text.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Box(
      style: BoxStyler().paddingBottom(space4()),
      child: AppFullWidthButton(
        child: AppButton(
          semanticLabel: semanticLabel,
          onPressed: onPressed,
          variant: AppButtonVariant.secondary,
          child: Text(label),
        ),
      ),
    );
  }
}
