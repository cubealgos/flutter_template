import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// The provider mark's fixed square size, in logical pixels — this
/// template's existing 44px minimum-hit-target convention.
const double _markSize = 44;

/// A small bordered placeholder avatar for a linked identity's provider —
/// a bordered square with its first initial.
class ProviderMark extends StatelessWidget {
  /// Creates the mark.
  const ProviderMark({required this.provider, super.key});

  /// The linked identity's provider name, e.g. `'google'` — only its first
  /// letter is shown, upper-cased.
  final String provider;

  @override
  Widget build(BuildContext context) {
    final initial = provider.isEmpty ? '?' : provider[0].toUpperCase();

    return Box(
      style: BoxStyler()
          .size(_markSize, _markSize)
          .borderAll(color: colorBorder(), width: strokeThin()),
      child: Center(
        child: StyledText(
          initial,
          style: TextStyler()
              .fontSize(productBody())
              .fontWeight(FontWeight.w600)
              .fontFamily(fontFamilyBody)
              .fontFamilyFallback(fontFamilyBodyFallback)
              .color(colorFgSubtle()),
        ),
      ),
    );
  }
}
