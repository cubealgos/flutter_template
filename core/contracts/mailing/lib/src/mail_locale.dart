/// The languages a mail can be written in: the app's own locales (`en` is the
/// base, `de` the second), mirroring `apps/app`'s slang setup.
enum MailLocale {
  /// English, the base and fallback locale.
  en('en'),

  /// German.
  de('de');

  const MailLocale(this.tag);

  /// The language tag (`en`, `de`).
  final String tag;

  /// The locale an unknown or missing tag falls back to, like slang's
  /// `fallback_strategy: base_locale`.
  static const MailLocale fallback = MailLocale.en;

  /// The locale for [tag] (`de`, `de-AT`, `DE_ch`): the language part decides;
  /// null or an unsupported language gives [fallback].
  static MailLocale parse(String? tag) {
    final language = (tag ?? '').toLowerCase().split(RegExp('[-_]')).first;
    for (final locale in values) {
      if (locale.tag == language) return locale;
    }

    return fallback;
  }
}
