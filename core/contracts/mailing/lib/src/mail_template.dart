import 'package:mailing/src/mail_locale.dart';
import 'package:mailing/src/mail_template_strings.dart';

/// A mail template with a text per locale.
///
/// **Why this is Dart, not the app's slang JSON.** `apps/app`'s i18n is
/// generated Flutter code (`strings.g.dart`, `slang_flutter`) from JSON files
/// under `apps/app/lib/i18n`, and the `api` Function is pure Dart built from
/// path dependencies without the app. A template that lives here is
/// available to the Function with no Flutter and no copy step, uses the same
/// `{name}` placeholders, the same `en` base locale and the same fallback,
/// and `MailCatalog` fails at construction when a locale is missing or its
/// placeholders differ, so the de/en parity slang's tooling gives the app is
/// enforced here too.
class MailTemplate {
  /// Creates a template.
  const MailTemplate({
    required this.id,
    required this.strings,
    this.subscription,
  });

  /// The ID messages name it by, snake_case.
  final String id;

  /// The text per locale; every [MailLocale] must be present.
  final Map<MailLocale, MailTemplateStrings> strings;

  /// The subscription this mail belongs to (`digest`), or null for a
  /// **transactional** mail (a receipt, a security notice) that the recipient
  /// cannot opt out of. A non-transactional mail always carries a one-click
  /// unsubscribe scoped to this subscription.
  final String? subscription;

  /// Whether the mail is transactional (no unsubscribe).
  bool get isTransactional => subscription == null;

  /// The text for [locale], falling back to the base locale like slang does.
  MailTemplateStrings stringsFor(MailLocale locale) =>
      strings[locale] ??
      strings[MailLocale.fallback] ??
      (throw StateError('Mail template "$id" has no base-locale text.'));
}
