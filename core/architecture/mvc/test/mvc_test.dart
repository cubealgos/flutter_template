import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvc/mvc.dart';

// --- Test fixtures: a minimal counter triad -------------------------------
//
// Mirrors sprout_state's own `sprout_state_test.dart` fixtures (this triad
// is vendored from it) — see lib/mvc.dart for the vendoring note.

// This is the package's root test entry file, conventionally named
// `mvc_test.dart` after the package, not after whichever fixture class
// happens to be declared first.
// ignore: solid_lints/prefer_match_file_name
class _CounterModel extends ViewModel {
  _CounterModel(this.count);
  final int count;
}

class _CounterController extends ViewController<_CounterModel> {
  _CounterController([int initial = 0]) : super(_CounterModel(initial));

  int initCalls = 0;
  bool disposed = false;

  @override
  void init() => initCalls++;

  void increment() => value = _CounterModel(value.count + 1);

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

/// A [ViewWidget] that returns a caller-supplied controller so the test can
/// inspect it (mirrors how an app injects a controller for testability).
class _CounterView extends ViewWidget<_CounterModel, _CounterController> {
  _CounterView(this._controller);
  final _CounterController _controller;

  @override
  _CounterController createController() => _controller;

  @override
  Widget build(
    BuildContext context,
    _CounterController controller,
    _CounterModel model,
  ) => Text('${model.count}', textDirection: TextDirection.ltr);
}

/// A view that mints a *fresh* controller from `createController()` each call
/// (as real screens do), whose controller loads state in `init()`. Used to
/// prove the controller is owned by the State, not the widget: a
/// widget-owned controller would be recreated (and left un-`init()`ed) on
/// every parent rebuild, dropping the loaded state.
int _autoCreateCount = 0;

/// The model value `_AutoController.init()` simulates having loaded.
const _loadedCount = 100;

class _AutoController extends ViewController<_CounterModel> {
  _AutoController() : super(_CounterModel(0));

  @override
  void init() => value = _CounterModel(_loadedCount);
}

class _AutoView extends ViewWidget<_CounterModel, _AutoController> {
  @override
  _AutoController createController() {
    _autoCreateCount++;

    return _AutoController();
  }

  @override
  Widget build(
    BuildContext context,
    _AutoController controller,
    _CounterModel model,
  ) => Text('${model.count}', textDirection: TextDirection.ltr);
}

/// A nested widget that shares the ancestor [_CounterView]'s controller.
class _CounterLabel
    extends InheritedViewWidget<_CounterModel, _CounterController> {
  @override
  Widget build(
    BuildContext context,
    _CounterController controller,
    _CounterModel model,
  ) => Text('nested:${model.count}', textDirection: TextDirection.ltr);
}

/// A [ViewWidget] whose body is a supplied child — used to host a
/// [_CounterLabel] under the controller injector.
class _NestingView extends ViewWidget<_CounterModel, _CounterController> {
  _NestingView({required this._controller, required this.child});
  final _CounterController _controller;
  final Widget child;

  @override
  _CounterController createController() => _controller;

  @override
  Widget build(
    BuildContext context,
    _CounterController controller,
    _CounterModel model,
  ) => child;
}

void main() {
  group('ViewController', () {
    test('is a ValueNotifier that notifies on value change', () {
      final controller = _CounterController();
      var notifications = 0;

      controller
        ..addListener(() => notifications++)
        ..increment();

      expect(controller.model.count, 1);
      expect(notifications, 1);
      controller.dispose();
    });

    test('init() defaults to a no-op and is not called on construction', () {
      final controller = _CounterController();
      expect(controller.initCalls, 0);
      controller.dispose();
    });
  });

  group('ViewWidget', () {
    testWidgets('calls init() once on mount and renders the model', (
      tester,
    ) async {
      final controller = _CounterController();
      await tester.pumpWidget(_CounterView(controller));

      expect(controller.initCalls, 1);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('rebuilds when the controller pushes a new model', (
      tester,
    ) async {
      final controller = _CounterController();
      await tester.pumpWidget(_CounterView(controller));

      controller.increment();
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('disposes its controller on unmount', (tester) async {
      final controller = _CounterController();
      await tester.pumpWidget(_CounterView(controller));

      await tester.pumpWidget(const SizedBox());

      expect(controller.disposed, isTrue);
    });

    testWidgets('keeps its controller (created & init()ed once) across parent '
        'rebuilds', (tester) async {
      _autoCreateCount = 0;
      await tester.pumpWidget(_AutoView());
      expect(find.text('100'), findsOneWidget); // init() loaded state
      expect(_autoCreateCount, 1);

      // A parent rebuild constructs a new _AutoView instance for the same
      // element. The controller must be owned by the State (created once),
      // not re-minted from the fresh widget — else the loaded state is lost.
      await tester.pumpWidget(_AutoView());
      await tester.pump();

      expect(
        _autoCreateCount,
        1,
        reason: 'controller must not be recreated on a parent rebuild',
      );
      expect(
        find.text('100'),
        findsOneWidget,
        reason: 'synced state must survive a parent rebuild',
      );
    });
  });

  group('InheritedViewWidget', () {
    testWidgets('reads the ancestor controller and rebuilds on change', (
      tester,
    ) async {
      final controller = _CounterController();
      // The parent view renders the nested label, which shares its
      // controller.
      await tester.pumpWidget(
        _NestingView(controller: controller, child: _CounterLabel()),
      );

      expect(find.text('nested:0'), findsOneWidget);

      controller.increment();
      await tester.pump();

      expect(find.text('nested:1'), findsOneWidget);
      // No manual dispose: the ancestor ViewWidget disposes the controller
      // on unmount at teardown (disposing here too would double-dispose).
    });
  });
}
