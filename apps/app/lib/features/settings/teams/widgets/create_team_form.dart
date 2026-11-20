import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:ui/ui.dart';

/// The "create a team" form: a name field and a button. The creator becomes
/// the team's owner.
class CreateTeamForm extends StatelessWidget {
  /// Creates the form.
  const CreateTeamForm({
    required this.nameController,
    required this.busy,
    required this.onCreate,
    super.key,
  });

  /// The name field's text controller.
  final TextEditingController nameController;

  /// Whether a call is running (shows a spinner on the button).
  final bool busy;

  /// Called when "Create team" is pressed.
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          label: t.settings.teams.nameLabel,
          controller: nameController,
        ),
        const AppGap.v2(),
        AppFullWidthButton(
          child: AppButton(
            semanticLabel: t.settings.teams.createButton,
            loading: busy,
            onPressed: onCreate,
            child: Text(t.settings.teams.createButton),
          ),
        ),
      ],
    );
  }
}
