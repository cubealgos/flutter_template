import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:naked_ui/naked_ui.dart';
import 'package:ui/src/components/dialog.dart' show AppDialogBarrier;
import 'package:ui/src/components/internal/dismiss_close_button.dart';
import 'package:ui/src/tokens.g.dart';

/// A bottom sheet's visual chrome: a full-width, surface-colored panel
/// pinned to the bottom of the screen, with a built-in accessible close
/// control.
///
/// naked_ui has no bottom-sheet primitive, so this is built directly on
/// [showGeneralDialog] (from `package:flutter/widgets.dart`) rather than a
/// `Naked*` widget; see [showAppSheet]. Wraps [child] in naked_ui's
/// [NakedDialog] for dialog-role semantics, same as `AppDialog`.
///
// This file is named for the component's role; the class carries this
// package's `App` prefix, so the two names don't literally match — same
// convention as core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class AppSheet extends StatelessWidget {
  /// Creates an `AppSheet`.
  const AppSheet({required this.child, required this.semanticLabel, super.key});

  /// The sheet's content, below the built-in close control.
  final Widget child;

  /// The accessible name announced when the sheet opens.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: NakedDialog(
        semanticLabel: semanticLabel,
        child: Box(
          style: _chromeStyle(),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [const DismissCloseButton(), child],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens [builder]'s content in an [AppSheet], sliding up from the bottom
/// of the screen via [showGeneralDialog].
///
/// Returns the value passed to `Navigator.pop`, or `null` if dismissed.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required String semanticLabel,
  required WidgetBuilder builder,
  AppDialogBarrier barrier = const AppDialogBarrier(),
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierColor: colorScrim.resolve(context),
    barrierDismissible: barrier.dismissible,
    barrierLabel: barrier.label ?? semanticLabel,
    transitionDuration: motionDurationStep.resolve(context),
    pageBuilder: (dialogContext, _, _) =>
        AppSheet(semanticLabel: semanticLabel, child: builder(dialogContext)),
    transitionBuilder: _slideUpTransition,
  );
}

// Must return a Widget directly, not be a widget class: it fills
// RouteTransitionsBuilder, a function typedef, not a widget-class slot.
// ignore: solid_lints/avoid_returning_widgets
/// Slides [child] up from the bottom of the screen as [animation] runs.
///
/// Must be a plain function, not a widget class, to match
/// [RouteTransitionsBuilder]'s signature — [showGeneralDialog]'s
/// `transitionBuilder` parameter.
Widget _slideUpTransition(
  BuildContext _,
  Animation<double> animation,
  Animation<double> _,
  Widget child,
) {
  final offset = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: animation, curve: motionEaseStandard));

  return SlideTransition(position: offset, child: child);
}

/// The sheet chrome's fill, top corner radius, and padding.
BoxStyler _chromeStyle() {
  return BoxStyler()
      .color(colorSurface())
      .borderRadiusTop(radiusLg())
      .borderAll(color: colorBorder(), width: strokeThin())
      .paddingAll(space6());
}
