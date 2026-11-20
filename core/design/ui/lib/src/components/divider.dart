import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/src/tokens.g.dart';

/// A full-width hairline section boundary.
///
/// No such primitive exists today — sections (e.g. Account Settings'
/// "danger zone", spec.md §2.12) are currently separated only by a
/// `SizedBox` gap, which reads as extra whitespace rather than a
/// deliberate boundary. Matches the mockups' `.divider` (`height: 1px;
/// background: var(--edge)`).
///
// This file is named for the component's role; the class carries this
// package's `App` prefix, so the two names don't literally match — same
// convention as core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class AppDivider extends StatelessWidget {
  /// Creates an `AppDivider`.
  const AppDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Box(
      style: BoxStyler()
          .width(double.infinity)
          .height(strokeThin())
          .color(colorBorder()),
    );
  }
}
