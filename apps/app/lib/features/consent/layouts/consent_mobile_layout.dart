import 'package:app/features/consent/widgets/consent_card.dart';
import 'package:flutter/widgets.dart';
import 'package:ui/ui.dart';

/// The consent sheet: the card pinned to the bottom of a full-height,
/// auth-width column. There is no wider variant — the sheet keeps the same
/// narrow column on every viewport.
class ConsentMobileLayout extends StatelessWidget {
  /// Creates the layout.
  const ConsentMobileLayout({
    required this.onReject,
    required this.onAccept,
    required this.onOpenSettings,
    super.key,
  });

  /// Called when Reject is pressed.
  final VoidCallback onReject;

  /// Called when Accept is pressed.
  final VoidCallback onAccept;

  /// Called when the Settings → Privacy link is pressed.
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // `AppContentWrapper` only caps width and top-aligns; this screen
      // needs full-height, bottom-anchored placement (a sheet pinned to
      // the bottom), so it adds its own `minHeight` floor from the local
      // constraints (a height, not a breakpoint).
      child: LayoutBuilder(
        builder: (_, constraints) => AppContentWrapper(
          width: AppContentWidth.auth,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: ConsentCard(
              onReject: onReject,
              onAccept: onAccept,
              onOpenSettings: onOpenSettings,
            ),
          ),
        ),
      ),
    );
  }
}
