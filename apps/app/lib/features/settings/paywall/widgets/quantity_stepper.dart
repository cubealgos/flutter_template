import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// A "- n +" control for the number of units (monitored sites, seats).
class QuantityStepper extends StatelessWidget {
  /// Creates the stepper.
  const QuantityStepper({
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
    super.key,
  });

  /// The chosen quantity.
  final int quantity;

  /// Called when "+" is pressed.
  final VoidCallback onIncrease;

  /// Called when "-" is pressed.
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: StyledText(
            t.settings.paywall.quantityLabel,
            style: bodyStyle(),
          ),
        ),
        AppButton(
          semanticLabel: t.settings.paywall.decreaseLabel,
          onPressed: quantity > 1 ? onDecrease : null,
          disabled: quantity <= 1,
          variant: AppButtonVariant.secondary,
          child: const Text('-'),
        ),
        const AppGap.h3(),
        StyledText('$quantity', style: h2Style()),
        const AppGap.h3(),
        AppButton(
          semanticLabel: t.settings.paywall.increaseLabel,
          onPressed: onIncrease,
          variant: AppButtonVariant.secondary,
          child: const Text('+'),
        ),
      ],
    );
  }
}
