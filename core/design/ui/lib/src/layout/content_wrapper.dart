import 'package:flutter/widgets.dart';

/// Constrains [child] to an [AppContentWidth] preset and centers it —
/// applied at the screen-shell level so a screen's rows, buttons, and body
/// text stop stretching edge-to-edge at desktop/web widths (spec.md §3,
/// Pattern C: currently **zero** of the 13 screens constrain width at
/// all).
///
/// `AppScreenScaffold` already wraps its `body` in one of these; reach for
/// this directly only when a screen needs a different-width column than
/// its scaffold's default (e.g. Home's header spans full width while its
/// content column is capped, spec.md §2.6).
///
// This file is named for the component's role; the class carries this
// package's `App` prefix, so the two names don't literally match — same
// convention as core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class AppContentWrapper extends StatelessWidget {
  /// Creates an `AppContentWrapper`.
  const AppContentWrapper({
    required this.width,
    required this.child,
    super.key,
  });

  /// Which width preset constrains [child].
  final AppContentWidth width;

  /// The content to constrain and center.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // `Align(topCenter)`, not `Center`: this widget's job is a width cap,
    // not a vertical one — `Center` also centered vertically, leaving a
    // large empty band above/below any screen shorter than the viewport.
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width.maxWidth),
        child: child,
      ),
    );
  }
}

/// A named content-width preset, per spec.md §1.1's max-width table.
enum AppContentWidth {
  /// 440px — auth/dialog screens (sign-in, consent, permission
  /// pre-prompt): a single centered "card" of content.
  auth(440),

  /// 640px — settings/list screens: rows fill the width, but the whole
  /// list stays centered rather than stretching edge-to-edge.
  list(640),

  /// ~65ch — long-text/legal reading measure. Bringhurst's classic
  /// 45–75-character-per-line guideline, corroborated by Baymard's
  /// ecommerce-copy readability study (spec.md §1.1). A [TextStyle] has no
  /// native `ch` unit, so this is a fixed pixel approximation: 65
  /// characters × 16px `body` × ~0.55em average glyph advance for a
  /// sans-serif face ≈ 572px, rounded up to 576px to stay on this
  /// package's 4px grid (`grid.unit`, `dimension.json`) — a genuine
  /// approximation, not a token-derived exact value, since no `ch`-aware
  /// token type exists in this token set.
  reading(576),

  /// 960px — home/dashboard screens: full-bleed background, centered
  /// content column.
  wide(960);

  /// Creates a content-width preset.
  AppContentWidth(this.maxWidth);

  /// This preset's maximum content width, in logical pixels.
  final double maxWidth;
}

/// Stretches [child] — typically a lone primary `AppButton` — to fill the
/// available width.
///
/// `AppButton` sizes to its content by design (a minimum, not a fixed,
/// hit target), so a lone primary submit button is content-width unless
/// wrapped like this. Today that only happens incidentally, inside a `Row`
/// + `Expanded` equal-weight pair (spec.md §3, Pattern D) — this is the
/// explicit single-button equivalent, named so a screen reaches for a
/// convention instead of reinventing `SizedBox(width: double.infinity)`
/// at each call site.
class AppFullWidthButton extends StatelessWidget {
  /// Creates an `AppFullWidthButton`.
  const AppFullWidthButton({required this.child, super.key});

  /// The button to stretch — an `AppButton`, in practice.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: double.infinity, child: child);
  }
}
