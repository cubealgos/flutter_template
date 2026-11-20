import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// One dot of the stepper's progress indicator, filled when [active].
class StepDot extends StatelessWidget {
  /// Creates the dot.
  const StepDot({required this.active, super.key});

  /// Whether this dot marks the current step.
  final bool active;

  @override
  Widget build(BuildContext context) {
    var style = BoxStyler()
        .size(space2(), space2())
        .borderAll(
          color: active ? colorAccent() : colorBorder(),
          width: strokeThin(),
        );
    if (active) style = style.color(colorAccent());

    return Box(style: style);
  }
}
