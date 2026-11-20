import 'package:flutter/widgets.dart';

/// One line segment (`x1, y1, x2, y2`) in a 24×24 viewBox, for
/// [LinesPainter].
typedef IconLine = (double, double, double, double);

/// Paints a set of [lines], each scaled from a 24×24 viewBox to this
/// widget's own size — shared, minimal stand-in for a proper icon
/// font/SVG pipeline this template doesn't depend on (matches
/// `AppChevronIcon`'s own approach).
class LinesPainter extends CustomPainter {
  /// Creates the painter.
  const LinesPainter({required this.color, required this.lines});

  static const double _viewBoxSize = 24;
  static const double _strokeWidth = 2;

  /// The stroke colour.
  final Color color;

  /// The line segments to draw, in viewBox coordinates.
  final List<IconLine> lines;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final scale = size.width / _viewBoxSize;

    for (final (x1, y1, x2, y2) in lines) {
      canvas.drawLine(
        Offset(x1 * scale, y1 * scale),
        Offset(x2 * scale, y2 * scale),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant LinesPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.lines != lines;
}
