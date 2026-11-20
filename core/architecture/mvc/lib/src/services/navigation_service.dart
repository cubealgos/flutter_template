import 'package:go_router/go_router.dart';

/// Screen navigation, injected into a `ViewController` instead of a view
/// reaching for `Navigator`/`context.go` itself.
///
/// A controller depends on this interface, not on [GoRouterNavigationService]
/// directly, so a controller unit test can inject a fake/mock instead of
/// standing up a real router. `core/architecture/mvc_lints`' `avoid_view_navigation_calls`
/// and `avoid_view_restricted_imports` rules enforce the other half of the
/// boundary: a view may not call `Navigator`/`context.go` or import
/// `go_router` at all — only a controller, via this service, may navigate.
abstract class NavigationService {
  /// Replaces the current location with [location], without adding an entry
  /// to the navigation history (`GoRouter.go`).
  void go(String location);

  /// Pushes [location] onto the navigation stack, returning a future that
  /// completes with the value later passed to [pop] for this new entry
  /// (`GoRouter.push`).
  Future<T?> push<T extends Object?>(String location);

  /// Pops the current location off the navigation stack, completing the
  /// future returned by the [push] that pushed it with [result]
  /// (`GoRouter.pop`).
  void pop<T extends Object?>([T? result]);

  /// Whether there is a location to [pop] back to.
  bool canPop();

  /// Replaces the current location with [location] without changing the
  /// navigation stack's depth (`GoRouter.replace`) — unlike [go], this keeps
  /// the same stack position rather than resetting it. Returns a future that
  /// completes with the value later passed to [pop] for the replacement
  /// entry, mirroring [push].
  Future<T?> replace<T extends Object?>(String location);
}

/// The default [NavigationService], wrapping a [GoRouter] instance that is
/// constructor-injected rather than looked up as a global/singleton.
///
/// This is the only file in `package:mvc` (besides its own test) that may
/// import `package:go_router` — see [NavigationService].
class GoRouterNavigationService implements NavigationService {
  /// Creates a service that delegates every call to [router].
  const GoRouterNavigationService(this.router);

  /// The wrapped router. Exposed so app wiring can still reach
  /// router-specific configuration (e.g. `router.routerDelegate`) where the
  /// [NavigationService] interface deliberately doesn't.
  final GoRouter router;

  @override
  void go(String location) => router.go(location);

  @override
  Future<T?> push<T extends Object?>(String location) =>
      router.push<T>(location);

  @override
  void pop<T extends Object?>([T? result]) => router.pop<T>(result);

  @override
  bool canPop() => router.canPop();

  @override
  Future<T?> replace<T extends Object?>(String location) =>
      router.replace<T>(location);
}
