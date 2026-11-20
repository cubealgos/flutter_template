import 'package:app/features/legal/licences/licence_group.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// The list/empty/loading body of the licences page: a spinner while
/// [loading], an empty-state message when there are no [entries], otherwise
/// one tappable tile per package.
class LicencesBody extends StatelessWidget {
  /// Creates the body.
  const LicencesBody({
    required this.loading,
    required this.entries,
    required this.onEntryTap,
    super.key,
  });

  /// Whether the licence registry is still being read.
  final bool loading;

  /// The licences, grouped by package.
  final List<LicenceGroup> entries;

  /// Called with the tapped package's licence group.
  final ValueChanged<LicenceGroup> onEntryTap;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: AppLoadingIndicator());
    }
    if (entries.isEmpty) {
      return StyledText(t.legal.licences.empty, style: bodyStyle());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final entry in entries)
          AppListTile(
            title: entry.packageName,
            trailing: const AppChevronIcon(
              direction: AppChevronDirection.end,
              color: colorFgSubtle,
            ),
            onTap: () => onEntryTap(entry),
          ),
      ],
    );
  }
}
