import 'package:flutter/widgets.dart';
import 'package:ui/ui.dart';

/// Caps [child] to the same narrow, dialog-weight column the desktop
/// mockups use for the setup card and sign-out button — even inside
/// Home's wider (960px) content area, where only the empty state and the
/// full-bleed header actually use that extra width. `AppContentWidth.auth`
/// (440px) matches the mockups' value exactly.
class NarrowColumn extends StatelessWidget {
  /// Creates the column.
  const NarrowColumn({required this.child, super.key});

  /// The widget to cap and center.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: AppContentWidth.auth.maxWidth),
        child: child,
      ),
    );
  }
}
