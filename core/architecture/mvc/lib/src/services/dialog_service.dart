import 'package:flutter/widgets.dart';

/// Showing and dismissing a dialog overlay, injected into a `ViewController`
/// instead of a view driving `Navigator`/route machinery itself.
///
/// Deliberately distinct from `NavigationService`: a dialog is overlay
/// machinery layered on top of the current screen, not a new entry on the
/// router's location stack, so dismissing one is [close], never
/// `NavigationService.pop`. A controller depends on this interface, not on
/// [OverlayDialogService] directly, so a controller unit test can inject a
/// fake/mock instead of a real overlay.
abstract class DialogService {
  /// Shows a dialog built by [builder] as an overlay above the current
  /// screen, returning a future that completes with the value passed to
  /// [close] when it is dismissed (or `null` if dismissed by tapping the
  /// barrier).
  Future<T?> show<T extends Object?>(WidgetBuilder builder);

  /// Dismisses the current dialog overlay, completing the future returned
  /// by [show] with [result].
  void close<T extends Object?>([T? result]);
}

/// The default [DialogService]. Uses `showGeneralDialog` from
/// `package:flutter/widgets.dart` directly — never
/// `package:flutter/material.dart`'s `showDialog`, since this template
/// forbids Material widgets — layered over the [Navigator] reached through a
/// constructor-injected `GlobalKey<NavigatorState>`.
class OverlayDialogService implements DialogService {
  /// Creates a service that shows dialogs above the [Navigator] attached to
  /// [navigatorKey] (typically the same key passed as
  /// `MaterialApp.navigatorKey` or `WidgetsApp.navigatorKey` when the app is
  /// wired up).
  const OverlayDialogService(this.navigatorKey);

  /// The key identifying the [Navigator] whose overlay dialogs are shown
  /// above, and whose root is popped to dismiss one.
  final GlobalKey<NavigatorState> navigatorKey;

  BuildContext get _context {
    final context = navigatorKey.currentContext;
    if (context == null) {
      throw StateError(
        'OverlayDialogService: navigatorKey is not attached to a '
        'NavigatorState — has the app finished its first frame?',
      );
    }

    return context;
  }

  @override
  Future<T?> show<T extends Object?>(WidgetBuilder builder) {
    return showGeneralDialog<T>(
      context: _context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      pageBuilder: (context, _, _) => builder(context),
    );
  }

  @override
  void close<T extends Object?>([T? result]) {
    Navigator.of(_context, rootNavigator: true).pop<T>(result);
  }
}
