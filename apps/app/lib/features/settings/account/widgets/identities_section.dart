import 'package:app/features/settings/account/widgets/provider_mark.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:auth/auth.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// The linked-identities section: a loading spinner, an empty-state
/// message, or a list of `AppListTile`s with a "Disconnect" trailing
/// button.
class IdentitiesSection extends StatelessWidget {
  /// Creates the section.
  const IdentitiesSection({
    required this.loading,
    required this.identities,
    required this.onDisconnect,
    super.key,
  });

  /// Whether the identities are still being loaded.
  final bool loading;

  /// The user's linked social identities.
  final List<LinkedIdentity> identities;

  /// Called with the id of the identity whose "Disconnect" button was
  /// pressed.
  final ValueChanged<String> onDisconnect;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Box(
        style: BoxStyler().paddingY(space4()),
        child: const Center(child: AppLoadingIndicator()),
      );
    }
    if (identities.isEmpty) {
      return StyledText(
        t.settings.account.noLinkedIdentities,
        style: bodyStyle(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final identity in identities)
          AppListTile(
            title: identity.provider,
            subtitle: identity.providerEmail,
            leading: ProviderMark(provider: identity.provider),
            trailing: AppButton(
              semanticLabel:
                  '${t.settings.account.disconnectButton} ${identity.provider}',
              onPressed: () => onDisconnect(identity.id),
              variant: AppButtonVariant.secondary,
              child: Text(t.settings.account.disconnectButton),
            ),
          ),
      ],
    );
  }
}
