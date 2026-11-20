import 'package:flutter/services.dart';

/// Copying text to the system clipboard, injected into a `ViewController`
/// instead of a view calling `Clipboard.setData` itself.
///
/// A controller depends on this interface, not on [SystemClipboardService]
/// directly, so a controller unit test can inject a fake instead of
/// touching the platform clipboard channel. Mirrors `LauncherService`'s
/// seam — added for the data-export/licence-text "copy" affordance,
/// since this template has no Material `SelectableText`/`SelectionArea` to
/// reach for.
abstract class ClipboardService {
  /// Copies [text] to the system clipboard.
  Future<void> copyText(String text);
}

/// The default [ClipboardService], wrapping
/// `package:flutter/services.dart`'s [Clipboard.setData].
class SystemClipboardService implements ClipboardService {
  /// Creates the service. Stateless — like `UrlLauncherService`, the
  /// platform clipboard channel is process-global, so there is nothing to
  /// inject here; the seam this class exists for is the [ClipboardService]
  /// interface it implements, not constructor state.
  const SystemClipboardService();

  @override
  Future<void> copyText(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
