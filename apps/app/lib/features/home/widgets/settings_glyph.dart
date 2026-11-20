import 'package:app/features/home/widgets/lines_painter.dart';
import 'package:flutter/widgets.dart';
import 'package:ui/ui.dart';

/// The settings (sliders) icon in Home's header.
class SettingsGlyph extends StatelessWidget {
  /// Creates the glyph.
  const SettingsGlyph({super.key});

  static const double _size = 20;

  static const List<IconLine> _lines = [
    (4, 21, 4, 14),
    (4, 10, 4, 3),
    (12, 21, 12, 12),
    (12, 8, 12, 3),
    (20, 21, 20, 16),
    (20, 12, 20, 3),
    (1, 14, 7, 14),
    (9, 8, 15, 8),
    (17, 16, 23, 16),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(_size, _size),
      painter: LinesPainter(color: colorFg.resolve(context), lines: _lines),
    );
  }
}
