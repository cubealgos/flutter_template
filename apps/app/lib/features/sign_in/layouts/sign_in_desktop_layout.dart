import 'package:flutter/widgets.dart';
import 'package:ui/ui.dart';

/// Sign-in from the desktop breakpoint: the [form] centered vertically in
/// the auth-width column, matching `SignInEmail-desktop-dark.dc.html`.
class SignInDesktopLayout extends StatelessWidget {
  /// Creates the layout.
  const SignInDesktopLayout({required this.form, super.key});

  /// The sign-in form (`SignInForm`) to lay out.
  final Widget form;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // Centered within the available `maxHeight`, so the local constraints
      // are needed here (the breakpoint itself is `ResponsiveLayout`'s, from
      // the viewport).
      child: LayoutBuilder(
        builder: (_, constraints) => AppContentWrapper(
          width: AppContentWidth.auth,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(child: form),
            ),
          ),
        ),
      ),
    );
  }
}
