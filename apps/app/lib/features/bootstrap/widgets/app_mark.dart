import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// A placeholder brand mark: two nested squares, matching
/// `BlockedVersion-phone-*.dc.html`'s abstract logo placeholder — every
/// value here is an existing space token (`space12`/`space6`/`space3`),
/// not an ad-hoc size, per this template's "tokens and components only"
/// rule. A cloned app replaces this with its own real app icon/logo.
class AppMark extends StatelessWidget {
  /// Creates the mark.
  const AppMark({super.key});

  @override
  Widget build(BuildContext context) {
    // space12 (48px) border plus space3 (12px) padding on every side
    // leaves exactly a space6 (24px) box for the inner square — padding,
    // not `Positioned`, so every offset stays a `BoxStyler` token.
    return Box(
      style: BoxStyler()
          .size(space12(), space12())
          .borderAll(color: colorAccent(), width: strokeStrong())
          .paddingAll(space3()),
      child: Box(
        style: BoxStyler().size(space6(), space6()).color(colorAccent()),
      ),
    );
  }
}
