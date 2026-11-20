import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:naked_ui/naked_ui.dart';
import 'package:ui/src/components/internal/dismiss_close_button.dart';
import 'package:ui/src/tokens.g.dart';

/// The dialog chrome's maximum width, in logical pixels.
const double _maxDialogWidth = 480;

/// The dialog's visual chrome: a centered, bordered, surface-colored card
/// with a built-in accessible close control.
///
/// Wraps [child] in naked_ui's [NakedDialog] for dialog role semantics.
/// Pair with [showAppDialog] rather than constructing this directly, so
/// the surrounding route, barrier, and focus handling are wired up too.
///
// This file is named for the component's role; the class carries this
// package's `App` prefix, so the two names don't literally match — same
// convention as core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class AppDialog extends StatelessWidget {
  /// Creates an `AppDialog`.
  const AppDialog({
    required this.child,
    required this.semanticLabel,
    super.key,
  });

  /// The dialog's content, below the built-in close control.
  final Widget child;

  /// The accessible name announced when the dialog opens.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: NakedDialog(
        semanticLabel: semanticLabel,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxDialogWidth),
          child: Box(
            style: _chromeStyle(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [const DismissCloseButton(), child],
            ),
          ),
        ),
      ),
    );
  }
}

/// Barrier-dismissal configuration shared by [showAppDialog] and
/// `showAppSheet` — bundled into its own type so neither function exceeds
/// this workspace's 4-parameter limit for ordinary functions.
class AppDialogBarrier {
  /// Creates a barrier configuration.
  const AppDialogBarrier({this.label, this.dismissible = true});

  /// Whether tapping outside the dialog dismisses it.
  final bool dismissible;

  /// The accessible label announced for the dismiss barrier.
  final String? label;
}

/// Opens [builder]'s content in an [AppDialog], using naked_ui's
/// [showNakedDialog] for the route, barrier, and focus-trap plumbing.
///
/// Returns the value passed to `Navigator.pop`, or `null` if dismissed.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String semanticLabel,
  required WidgetBuilder builder,
  AppDialogBarrier barrier = const AppDialogBarrier(),
}) {
  return showNakedDialog<T>(
    context: context,
    barrierColor: colorScrim.resolve(context),
    barrierDismissible: barrier.dismissible,
    barrierLabel: barrier.label,
    builder: (dialogContext) =>
        AppDialog(semanticLabel: semanticLabel, child: builder(dialogContext)),
  );
}

/// The dialog chrome's fill, border, and corner radius.
BoxStyler _chromeStyle() {
  return BoxStyler()
      .color(colorSurface())
      .borderRadiusAll(radiusLg())
      .borderAll(color: colorBorder(), width: strokeThin())
      .paddingAll(space6());
}
