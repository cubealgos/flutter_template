import 'package:app/features/home/widgets/lines_painter.dart';
import 'package:flutter/widgets.dart';
import 'package:ui/ui.dart';

/// The empty-tray icon shown above Home's empty-state message.
class TrayGlyph extends StatelessWidget {
  /// Creates the glyph.
  const TrayGlyph({super.key});

  static const double _size = 40;

  static const List<IconLine> _lines = [
    (2, 12, 8, 12),
    (8, 12, 10, 15),
    (14, 15, 16, 12),
    (16, 12, 22, 12),
    (2, 12, 5.45, 5.11),
    (5.45, 5.11, 16.76, 4),
    (16.76, 4, 22, 12),
    (2, 12, 2, 18),
    (22, 12, 22, 18),
    (2, 18, 4, 20),
    (4, 20, 20, 20),
    (20, 20, 22, 18),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(_size, _size),
      painter: LinesPainter(
        color: colorFgSubtle.resolve(context),
        lines: _lines,
      ),
    );
  }
}
