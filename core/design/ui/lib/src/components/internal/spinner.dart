import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// One full turn, in radians.
const double _fullTurnRadians = math.pi + math.pi;

/// The fraction of a full turn the spinner's arc sweeps.
const double _spinnerSweepFraction = 0.75;

/// Halves [_SpinnerPainter.strokeWidth] to inset the paint rect by, so the
/// stroke itself stays fully within the painter's [Size] rather than being
/// clipped at the edge.
const double _strokeInsetDivisor = 2;

/// A small rotating-arc loading indicator, painted without any Material
/// dependency — shared by `AppButton`'s built-in loading state and the
/// standalone `AppLoadingIndicator` (spec.md §3, Pattern E: a screen-level
/// `loading` model field with nothing rendered for it, e.g. Licences and
/// Account Settings while their lists load).
class Spinner extends StatefulWidget {
  /// Creates a `Spinner`.
  const Spinner({
    required this.color,
    required this.period,
    super.key,
    this.diameter = 16,
    this.strokeWidth = 2,
  });

  /// The arc's stroke color, already resolved against the current theme.
  final Color color;

  /// How long one full rotation takes.
  final Duration period;

  /// The spinner's fixed square size, in logical pixels.
  final double diameter;

  /// The arc's stroke width, in logical pixels.
  final double strokeWidth;

  @override
  State<Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<Spinner> {
  Timer? _timer;
  double _turns = 0;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(widget.period, _advance);
  }

  void _advance(Timer timer) {
    setState(() {
      _turns += 1;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: _turns,
      duration: widget.period,
      child: CustomPaint(
        size: Size(widget.diameter, widget.diameter),
        painter: _SpinnerPainter(
          color: widget.color,
          strokeWidth: widget.strokeWidth,
        ),
      ),
    );
  }
}

/// Paints a single rotating stroke arc for [Spinner].
class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter({required this.color, required this.strokeWidth});

  /// The arc's stroke color.
  final Color color;

  /// The arc's stroke width, in logical pixels.
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final rect = (Offset.zero & size).deflate(
      strokeWidth / _strokeInsetDivisor,
    );
    const sweepAngle = _fullTurnRadians * _spinnerSweepFraction;

    canvas.drawArc(rect, 0, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
