import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/src/tokens.g.dart';

/// The chevron's fixed square size, in logical pixels — matches the
/// mockups' back-button glyph (`width="20" height="24" viewBox="0 0 24
/// 24"`, back button variant).
const double _chevronSize = 20;

/// The stroke width, in logical pixels — matches the mockups' SVG
/// (`stroke-width="2"`).
const double _chevronStrokeWidth = 2;

/// The mockups' SVG viewBox is square, `0 0 24 24` — this glyph's path
/// coordinates below are all expressed against that box, then scaled to
/// [_chevronSize].
const double _viewBoxSize = 24;

/// The path's near-tip x-coordinate in the 24×24 viewBox — the mockups'
/// `M15 18l-6-6 6-6` (start) and `M9 18l6-6-6-6` (end) both meet at
/// x=9 or x=15 depending on direction; see [_ChevronPainter.paint].
const double _viewBoxTipXStart = 9;

/// The path's far x-coordinate in the 24×24 viewBox — the mirror of
/// [_viewBoxTipXStart].
const double _viewBoxTipXEnd = 15;

/// The path's top y-coordinate in the 24×24 viewBox.
const double _viewBoxTopY = 6;

/// The path's middle y-coordinate (the chevron's point) in the 24×24
/// viewBox.
const double _viewBoxMidY = 12;

/// The path's bottom y-coordinate in the 24×24 viewBox.
const double _viewBoxBottomY = 18;

/// A small chevron glyph, painted without any icon-font or Material
/// dependency (this package imports no `material.dart` anywhere).
///
/// Mirrors the mockups' inline SVG chevrons (a two-segment stroke path,
/// round cap and join, drawn on a 24×24 viewBox scaled to [_chevronSize])
/// — see `docs/design/mockups/SettingsHub-phone-light.dc.html`'s back
/// button and list-row disclosure glyphs. Purely decorative: wrap it in a
/// semantics-carrying control (e.g. `AppIconButton`) rather than using it
/// as a standalone tappable target.
///
// This file is named for the component's role; the class carries this
// package's `App` prefix, so the two names don't literally match — same
// convention as core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class AppChevronIcon extends StatelessWidget {
  /// Creates an `AppChevronIcon`.
  const AppChevronIcon({required this.direction, super.key, this.color});

  /// Which way the glyph points.
  final AppChevronDirection direction;

  /// The stroke color. Defaults to [colorFg] (the mockups' `--ink`, used
  /// for the header back button); pass [colorFgSubtle] for the muted
  /// disclosure-chevron treatment a navigational list row uses.
  final ColorToken? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = (color ?? colorFg).resolve(context);

    return CustomPaint(
      size: const Size(_chevronSize, _chevronSize),
      painter: _ChevronPainter(direction: direction, color: resolvedColor),
    );
  }
}

/// Which way an [AppChevronIcon] points.
enum AppChevronDirection {
  /// Points left — a back/previous affordance (`AppScreenHeader`'s back
  /// button).
  start,

  /// Points right — a forward/disclosure affordance (a navigational list
  /// row's trailing chevron).
  end,
}

/// Paints [AppChevronIcon]'s glyph.
class _ChevronPainter extends CustomPainter {
  const _ChevronPainter({required this.direction, required this.color});

  /// Which way the glyph points.
  final AppChevronDirection direction;

  /// The stroke color, already resolved against the current theme.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _chevronStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Scaled to this widget's own size rather than hard-coded to
    // `_viewBoxSize`, so [_chevronSize] stays the single source of truth.
    final scale = size.width / _viewBoxSize;
    final tipX = direction == AppChevronDirection.start
        ? _viewBoxTipXStart
        : _viewBoxTipXEnd;
    final outerX = direction == AppChevronDirection.start
        ? _viewBoxTipXEnd
        : _viewBoxTipXStart;

    final path = Path()
      ..moveTo(outerX * scale, _viewBoxTopY * scale)
      ..lineTo(tipX * scale, _viewBoxMidY * scale)
      ..lineTo(outerX * scale, _viewBoxBottomY * scale);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ChevronPainter oldDelegate) {
    return oldDelegate.direction != direction || oldDelegate.color != color;
  }
}
