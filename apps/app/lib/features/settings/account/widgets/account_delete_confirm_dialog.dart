import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:ui/ui.dart';

/// The delete-account confirmation dialog: shown via `DialogService.show`
/// from `AccountSettingsController.confirmAndDeleteAccount`, resolving
/// `true`/`false` through [onConfirm]/[onCancel] — a plain widget, not its
/// own MVC triad, since it has no state or navigation of its own beyond
/// those two callbacks the caller supplies.
class AccountDeleteConfirmDialog extends StatelessWidget {
  /// Creates the dialog.
  const AccountDeleteConfirmDialog({
    required this.onConfirm,
    required this.onCancel,
    super.key,
  });

  /// Called when the user confirms deletion.
  final VoidCallback onConfirm;

  /// Called when the user cancels.
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      semanticLabel: t.settings.account.deleteConfirmTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          StyledText(t.settings.account.deleteConfirmTitle, style: h3Style()),
          const AppGap.v2(),
          StyledText(
            t.settings.account.deleteConfirmMessage,
            style: bodyStyle(),
          ),
          const AppGap.v4(),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  semanticLabel: t.settings.account.deleteCancelButton,
                  onPressed: onCancel,
                  variant: AppButtonVariant.secondary,
                  child: Text(t.settings.account.deleteCancelButton),
                ),
              ),
              const AppGap.h3(),
              Expanded(
                child: AppButton(
                  semanticLabel: t.settings.account.deleteConfirmButton,
                  onPressed: onConfirm,
                  variant: AppButtonVariant.destructive,
                  child: Text(t.settings.account.deleteConfirmButton),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
