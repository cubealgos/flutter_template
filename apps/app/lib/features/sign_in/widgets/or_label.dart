import 'package:app/features/sign_in/widgets/or_divider.dart' show OrDivider;
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// The muted "or" text in the middle of [OrDivider].
class OrLabel extends StatelessWidget {
  /// Creates the label.
  const OrLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return StyledText(
      t.common.orDivider,
      style: bodySmStyle().color(colorFgSubtle()),
    );
  }
}
