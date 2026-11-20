import 'package:mailing/src/mail_invalid_error.dart';
import 'package:mailing/src/mail_locale.dart';
import 'package:mailing/src/mail_template.dart';
import 'package:mailing/src/mail_template_strings.dart';

/// The footer every non-transactional mail ends with in [locale]: plain text
/// and HTML, each with one `{url}` placeholder.
({String text, String html}) unsubscribeFooterFor(MailLocale locale) =>
    switch (locale) {
      MailLocale.en => (
        text:
            'You receive this email because you subscribed to these '
            'updates.\nUnsubscribe with one click: {url}',
        html:
            '<p>You receive this email because you subscribed to these '
            'updates. <a href="{url}">Unsubscribe</a></p>',
      ),
      MailLocale.de => (
        text:
            'Sie erhalten diese E-Mail, weil Sie diese Mitteilungen '
            'abonniert haben.\nMit einem Klick abbestellen: {url}',
        html:
            '<p>Sie erhalten diese E-Mail, weil Sie diese Mitteilungen '
            'abonniert haben. <a href="{url}">Abbestellen</a></p>',
      ),
    };

/// The templates a mailer can send, validated once.
///
/// Construction throws [ArgumentError] when two templates share an ID, a
/// template lacks a locale, or a locale's `{placeholders}` differ from the
/// base locale's: the parity check slang's tooling gives `apps/app`.
class MailCatalog {
  /// Creates a catalog over [templates].
  MailCatalog(Iterable<MailTemplate> templates)
    : _templates = <String, MailTemplate>{} {
    for (final template in templates) {
      if (_templates.containsKey(template.id)) {
        throw ArgumentError('Duplicate mail template "${template.id}".');
      }
      _validate(template);
      _templates[template.id] = template;
    }
  }

  final Map<String, MailTemplate> _templates;

  /// The IDs of every template.
  Iterable<String> get ids => _templates.keys;

  /// The template [id], or null.
  MailTemplate? templateFor(String id) => _templates[id];

  static void _validate(MailTemplate template) {
    final base = template.strings[MailLocale.fallback];
    if (base == null) {
      throw ArgumentError(
        'Mail template "${template.id}" has no ${MailLocale.fallback.tag} '
        'text (the base locale).',
      );
    }
    for (final locale in MailLocale.values) {
      final strings = template.strings[locale];
      if (strings == null) {
        throw ArgumentError(
          'Mail template "${template.id}" has no ${locale.tag} text.',
        );
      }
      if ((strings.html == null) != (base.html == null)) {
        throw ArgumentError(
          'Mail template "${template.id}": ${locale.tag} and '
          '${MailLocale.fallback.tag} must both have an html body or neither.',
        );
      }
      final missing = base.placeholders.difference(strings.placeholders);
      final extra = strings.placeholders.difference(base.placeholders);
      if (missing.isNotEmpty || extra.isNotEmpty) {
        throw ArgumentError(
          'Mail template "${template.id}": ${locale.tag} placeholders differ '
          'from ${MailLocale.fallback.tag} (missing $missing, extra $extra).',
        );
      }
    }
  }

  /// [text] with every `{name}` replaced from [data], through [escape].
  ///
  /// Throws [MailInvalidError] naming a placeholder [data] lacks.
  static String fill(
    String text,
    Map<String, String> data, {
    String Function(String value) escape = _identity,
  }) => text.replaceAllMapped(MailTemplateStrings.placeholderPattern, (match) {
    final name = match.group(1) ?? '';
    final value = data[name];
    if (value == null) {
      throw MailInvalidError('Missing mail data "$name".');
    }

    return escape(value);
  });

  static String _identity(String value) => value;
}
