import 'package:app/features/home/widgets/narrow_column.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:ui/ui.dart';

/// Home's secondary "Sign out" button in the narrow column — the same in
/// every layout.
class HomeSignOutButton extends StatelessWidget {
  /// Creates the button.
  const HomeSignOutButton({required this.onSignOut, super.key});

  /// Called when the button is pressed.
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return NarrowColumn(
      child: AppButton(
        semanticLabel: t.home.signOutButton,
        onPressed: onSignOut,
        variant: AppButtonVariant.secondary,
        child: Text(t.home.signOutButton),
      ),
    );
  }
}
