import 'package:app/features/home/widgets/settings_glyph.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:ui/ui.dart';

/// Home's screen chrome, shared by every layout: `AppScreenScaffold`'s
/// full-bleed header layout (spec.md §2.6) with the settings button, around
/// a layout-specific [body].
class HomeScreenFrame extends StatelessWidget {
  /// Creates the frame.
  const HomeScreenFrame({
    required this.onOpenSettings,
    required this.body,
    super.key,
  });

  /// Called when the header's settings button is pressed.
  final VoidCallback onOpenSettings;

  /// The layout-specific content below the header.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: t.home.title,
      headerFillsWidth: true,
      contentWidth: AppContentWidth.wide,
      scrollable: false,
      trailing: AppIconButton(
        icon: const SettingsGlyph(),
        semanticLabel: t.home.settingsButton,
        onPressed: onOpenSettings,
      ),
      body: body,
    );
  }
}
