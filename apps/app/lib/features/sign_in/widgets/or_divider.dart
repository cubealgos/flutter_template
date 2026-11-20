import 'package:app/features/sign_in/widgets/or_label.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// A horizontal "or" divider between the email step and the alternative
/// sign-in methods, matching the mockups' `<hr>` + "or" + `<hr>` row.
class OrDivider extends StatelessWidget {
  /// Creates the divider.
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Box(
      style: BoxStyler().paddingY(space6()),
      child: Row(
        children: <Widget>[
          const Expanded(child: AppDivider()),
          Box(style: BoxStyler().paddingX(space4()), child: const OrLabel()),
          const Expanded(child: AppDivider()),
        ],
      ),
    );
  }
}
