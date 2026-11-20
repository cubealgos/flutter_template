import 'package:app/app/app.dart';
import 'package:app/app/di.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

/// Bootstraps the app: wires up DI, then loads the device locale (falling
/// back to `en` — see `slang.yaml`) before inflating `App`.
///
/// The native splash is removed once the first frame is drawn. Without the
/// call, the web splash generated into `web/index.html` stays on top of the
/// running app; on Android and iOS the call is harmless.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) _enableWebSemantics();
  configureDependencies();
  LocaleSettings.useDeviceLocaleSync();
  runApp(const App());
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => FlutterNativeSplash.remove(),
  );
}

/// Keeps Flutter web's semantics tree (the `flt-semantics` DOM a screen
/// reader and axe read) built from the first frame.
///
/// On web the tree is otherwise built only after a user finds and activates
/// the visually hidden "Enable accessibility" placeholder, which a
/// screen-reader user may never find and which automated checks never see.
/// The handle is kept for the app's whole life. Web only:
/// on Android and iOS the platform's own accessibility services switch
/// semantics on when needed, and forcing it on would just cost performance.
/// No `AppConfig` switch: a clone has no reason to ship an inaccessible web
/// app, and one that really must drop the cost deletes this call.
void _enableWebSemantics() {
  // The handle is deliberately never disposed.
  SemanticsBinding.instance.ensureSemantics();
}
