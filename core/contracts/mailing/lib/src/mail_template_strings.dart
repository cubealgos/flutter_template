/// One locale's text of a template.
class MailTemplateStrings {
  /// Creates the strings; [html] is optional (a plain-text-only mail).
  const MailTemplateStrings({
    required this.subject,
    required this.text,
    this.html,
  });

  /// The subject line.
  final String subject;

  /// The plain-text body.
  final String text;

  /// The HTML body, or null for a text-only mail. Values are HTML-escaped
  /// when they fill its placeholders.
  final String? html;

  /// A `{name}` placeholder, the syntax slang's JSON files use too.
  static final RegExp placeholderPattern = RegExp(
    r'\{([A-Za-z][A-Za-z0-9_]*)\}',
  );

  /// Every `{name}` placeholder in the three texts.
  Set<String> get placeholders => <String>{
    for (final source in <String?>[subject, text, html])
      if (source != null)
        for (final match in placeholderPattern.allMatches(source))
          match.group(1) ?? '',
  };
}
