import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:ui/ui.dart';

/// The invite form: an email field and a "Send invitation" button.
class InviteForm extends StatelessWidget {
  /// Creates the form.
  const InviteForm({
    required this.emailController,
    required this.busy,
    required this.onInvite,
    super.key,
  });

  /// The email field's text controller.
  final TextEditingController emailController;

  /// Whether a call is running (shows a spinner on the button).
  final bool busy;

  /// Called when "Send invitation" is pressed.
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          label: t.settings.teams.members.emailLabel,
          controller: emailController,
        ),
        const AppGap.v2(),
        AppFullWidthButton(
          child: AppButton(
            semanticLabel: t.settings.teams.members.inviteButton,
            loading: busy,
            onPressed: onInvite,
            child: Text(t.settings.teams.members.inviteButton),
          ),
        ),
      ],
    );
  }
}
