import 'package:flutter/widgets.dart';
import 'package:ui/ui.dart';

/// Sign-in below the tablet breakpoint: the [form] in a top-anchored,
/// scrollable auth-width column (`AppContentWrapper`'s default).
class SignInMobileLayout extends StatelessWidget {
  /// Creates the layout.
  const SignInMobileLayout({required this.form, super.key});

  /// The sign-in form (`SignInForm`) to lay out.
  final Widget form;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AppContentWrapper(
        width: AppContentWidth.auth,
        child: SingleChildScrollView(child: form),
      ),
    );
  }
}
