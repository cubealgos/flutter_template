import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/src/components/screen_header.dart';
import 'package:ui/src/layout/content_wrapper.dart';
import 'package:ui/src/tokens.g.dart';

/// A screen's top-level layout: the shared `AppScreenHeader`, a
/// max-width-constrained, optionally scrollable content column, and safe-
/// area handling — the shell every screen in spec.md §2 assumes.
///
/// Two header layouts, matching the approved mockups' two real shapes:
/// - Most screens (Settings, Legal, Privacy, Account, Licences, Legal
///   Document, Paywall): the header sits *inside* the same width-capped
///   column as the body (`headerFillsWidth: false`, the default).
/// - Home: the header spans the full viewport width, with its own
///   bottom hairline, while the body content below it is still centered
///   and capped (`headerFillsWidth: true`) — confirmed against
///   `Home-desktop-dark.dc.html`, which renders the header's `max-width:
///   960px` column separately from — but at the same width as — the body
///   section below it.
///
// This file is named for the component's role; the class carries this
// package's `App` prefix, so the two names don't literally match — same
// convention as core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class AppScreenScaffold extends StatelessWidget {
  /// Creates an `AppScreenScaffold`.
  const AppScreenScaffold({
    required this.title,
    required this.body,
    super.key,
    this.back,
    this.trailing,
    this.contentWidth = AppContentWidth.list,
    this.headerFillsWidth = false,
    this.edgePadding = space4,
    this.scrollable = true,
  });

  /// The screen's title, passed straight to `AppScreenHeader`.
  final String title;

  /// The screen's content, below the header.
  final Widget body;

  /// The header's back affordance. `null` renders no back button.
  final AppScreenHeaderBack? back;

  /// Content shown after the title in the header, e.g. a trailing
  /// icon-only action.
  final Widget? trailing;

  /// Which `AppContentWidth` preset caps [body] (and, unless
  /// [headerFillsWidth] is set, the header too).
  final AppContentWidth contentWidth;

  /// Renders the header full-width, with its own bottom hairline,
  /// instead of inside [contentWidth]'s column — Home's layout (spec.md
  /// §2.6), not the other 12 screens'.
  final bool headerFillsWidth;

  /// The screen's edge padding. Defaults to `space4` (16px, dense
  /// screens); auth/consent/onboarding screens pass `space6` (24px) per
  /// spec.md §1.1.
  final SpaceToken edgePadding;

  /// Whether [body] scrolls when it overflows. `false` for a screen that
  /// manages its own scrolling (or never overflows, e.g. a short dialog
  /// body).
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final header = AppScreenHeader(
      title: title,
      back: back,
      trailing: trailing,
    );
    final paddedBody = Box(
      style: BoxStyler().paddingAll(edgePadding()),
      child: body,
    );
    final content = scrollable
        ? SingleChildScrollView(child: paddedBody)
        : paddedBody;

    return SafeArea(
      child: headerFillsWidth
          ? _FullBleedHeaderLayout(
              contentWidth: contentWidth,
              edgePadding: edgePadding,
              header: header,
              content: content,
            )
          : _InlineHeaderLayout(
              contentWidth: contentWidth,
              edgePadding: edgePadding,
              header: header,
              content: content,
            ),
    );
  }
}

/// Home's layout (spec.md §2.6): [header] spans the full width, with its
/// own bottom hairline, while [content] is still capped and centered
/// below it.
class _FullBleedHeaderLayout extends StatelessWidget {
  const _FullBleedHeaderLayout({
    required this.contentWidth,
    required this.edgePadding,
    required this.header,
    required this.content,
  });

  final AppContentWidth contentWidth;
  final SpaceToken edgePadding;
  final Widget header;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Box(
          style: BoxStyler().borderBottom(
            color: colorBorder(),
            width: strokeThin(),
          ),
          child: AppContentWrapper(
            width: contentWidth,
            child: Box(
              style: BoxStyler().paddingAll(edgePadding()),
              child: header,
            ),
          ),
        ),
        Expanded(
          child: AppContentWrapper(width: contentWidth, child: content),
        ),
      ],
    );
  }
}

/// The other 12 screens' layout: [header] sits inside the same
/// width-capped column as [content].
class _InlineHeaderLayout extends StatelessWidget {
  const _InlineHeaderLayout({
    required this.contentWidth,
    required this.edgePadding,
    required this.header,
    required this.content,
  });

  final AppContentWidth contentWidth;
  final SpaceToken edgePadding;
  final Widget header;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return AppContentWrapper(
      width: contentWidth,
      child: Column(
        children: [
          Box(
            style: BoxStyler()
                .paddingX(edgePadding())
                .paddingTop(edgePadding()),
            child: header,
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}
