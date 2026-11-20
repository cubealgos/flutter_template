/// This template's MVC package.
///
/// Three parts:
///
/// - **The view triad** ([ViewModel], [ViewController], [ViewWidget],
///   [InheritedViewWidget]) is vendored from `sprout_state` 0.3.0
///   (a `ValueNotifier` + `InheritedWidget` state layer,
///   MIT-licensed, preferred over every third-party MVC library) with its
///   public API and semantics kept identical — see each `lib/src/` file's
///   own header for the vendoring note. An immutable [ViewModel] (typically
///   a `freezed` class) is owned by a [ViewController] (a `ValueNotifier`
///   that holds behaviour and pushes new models), rendered by a dumb
///   [ViewWidget] that rebuilds on model change. [InheritedViewWidget] lets
///   a nested widget read an ancestor's controller.
/// - **`ResponsiveLayout`** picks one of up to three layouts (mobile,
///   tablet, desktop, falling back to the narrower ones) by viewport width.
///   A feature's single [ViewWidget] owns the controller and builds one, so
///   crossing a breakpoint never recreates the controller.
/// - **The services** ([NavigationService], [LauncherService],
///   [DialogService], [ClipboardService]) are what a [ViewController]
///   injects to reach outside itself — screen navigation, external URLs,
///   dialog overlays, the system clipboard — so a view never has to (views
///   stay dumb and navigate only through injected services); see
///   `core/architecture/mvc_lints` for the analyzer rules that enforce a
///   view never importing `go_router`/`url_launcher` or calling
///   `Navigator`/`context.go` directly.
library;

import 'package:flutter/widgets.dart';
import 'package:mvc/src/services/clipboard_service.dart';
import 'package:mvc/src/services/dialog_service.dart';
import 'package:mvc/src/services/launcher_service.dart';
import 'package:mvc/src/services/navigation_service.dart';

export 'src/responsive_layout.dart';
export 'src/services/clipboard_service.dart';
export 'src/services/dialog_service.dart';
export 'src/services/launcher_service.dart';
export 'src/services/navigation_service.dart';

part 'src/view_widget.dart';
part 'src/view_controller.dart';
part 'src/view_model.dart';
part 'src/inherited_view_widget.dart';
part 'src/view_controller_injector.dart';
