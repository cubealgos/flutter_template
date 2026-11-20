import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/src/components/chevron_icon.dart';
import 'package:ui/src/components/icon_button.dart';
import 'package:ui/src/layout/app_gap.dart';
import 'package:ui/src/typography/text_styles.dart';

/// The minimum logical-pixel height of an [AppScreenHeader] row — matches
/// this package's existing 44px hit-target convention (the mockups use an
/// ad hoc, untokenized 56px; 44px is the accessibility floor spec §1.1
/// already establishes everywhere else, so the header enforces that floor
/// instead of introducing a new, one-off height value).
const double _minHeaderHeight = 48;

/// The shared screen header: an optional back-chevron icon button, an
/// `h1` title, and an optional trailing action, in one row.
///
/// Replaces the current per-screen pattern of a full-width text "Back"
/// button stacked above a separately-padded title (spec.md §3, Pattern B),
/// independently duplicated across seven screens. Also covers Home's
/// different-shaped need (§2.6): a title plus a trailing icon-only
/// action, no back button — pass [trailing] and leave [back] `null`.
///
// This file is named for the component's role; the class carries this
// package's `App` prefix, so the two names don't literally match — same
// convention as core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class AppScreenHeader extends StatelessWidget {
  /// Creates an `AppScreenHeader`.
  const AppScreenHeader({
    required this.title,
    super.key,
    this.back,
    this.trailing,
  });

  /// The screen's title, styled `h1` — one per screen, per spec §1.2.
  final String title;

  /// The back affordance shown before [title]. `null` renders no back
  /// button (e.g. Home, which is never navigated *back* from).
  final AppScreenHeaderBack? back;

  /// Content shown after [title], e.g. an `AppIconButton` trailing action.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final backConfig = back;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minHeaderHeight),
      child: Row(
        children: [
          if (backConfig != null) ...[
            AppIconButton(
              icon: const AppChevronIcon(direction: AppChevronDirection.start),
              semanticLabel: backConfig.semanticLabel,
              onPressed: backConfig.onPressed,
            ),
            const AppGap.h1(),
          ],
          Expanded(child: StyledText(title, style: h1Style())),
          ?trailing,
        ],
      ),
    );
  }
}

/// [AppScreenHeader]'s back affordance, bundled into its own type (same
/// pattern as `AppDialogBarrier`) so both the label and the callback are
/// required together — a header with a back chevron but no accessible
/// name for it is not a valid state.
class AppScreenHeaderBack {
  /// Creates a back-affordance configuration.
  const AppScreenHeaderBack({
    required this.semanticLabel,
    required this.onPressed,
  });

  /// The accessible name announced for the back button (e.g. "Back" —
  /// this package owns no strings/i18n, so callers supply their own
  /// localized copy).
  final String semanticLabel;

  /// Called when the back button is activated.
  final VoidCallback onPressed;
}
