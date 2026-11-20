/// The single source for the template's placeholder legal-entity facts
/// — a pure-Dart, Flutter-free package under `core/contracts/`
/// (not `packages/`: these facts are part of the template's own required
/// skeleton, read by both `apps/app` and `apps/website` from day one, not
/// an optional add-on or a clone-developed model the way `packages/domain`
/// is — see CLAUDE.md's "Workspace layout" row for the `core/`
/// vs. `packages/` distinction).
///
/// Previously, `apps/app/lib/app/config.dart`'s `AppConfig` declared these
/// as its own `legal*` field defaults and `apps/website` kept a duplicated
/// copy (`LegalPlaceholders`, kept in sync by a test that imported the
/// Flutter `app` package from the Flutter-free website — exactly the
/// coupling this package removes). Now both read from here: `AppConfig`'s
/// `legal*` fields default to these constants (still overridable per
/// build), and `apps/website`'s Impressum/Datenschutz pages read them
/// directly.
///
/// Every value is an **obvious placeholder** — a cloned app must replace
/// every field with its own lawyer-reviewed facts before shipping. None of
/// it is real personal or company data.
class LegalFacts {
  const LegalFacts._();

  /// The legal entity's registered company name, e.g. for the Impressum.
  static const String companyName = 'Example GmbH';

  /// The legal entity's registered address.
  static const String address = 'Musterstraße 1, 12345 Berlin, Germany';

  /// The commercial register entry (court and register number).
  static const String register = 'Amtsgericht Berlin, HRB 000000';

  /// The legal entity's VAT identification number.
  static const String vatId = 'DE000000000';

  /// The contact email shown on legal pages.
  static const String contactEmail = 'legal@example.com';

  /// The natural person responsible for content per § 18 (2) MStV.
  static const String responsiblePerson = 'Jane Doe';

  /// The supervisory authority shown on the Datenschutz page.
  static const String supervisoryAuthority =
      'Landesmedienanstalt Berlin-Brandenburg';

  /// The placeholder private security-disclosure contact (for
  /// `SECURITY.md`) — deliberately a separate field from [contactEmail]:
  /// a real clone's security inbox is very often a different address (and
  /// often a different team) from its general legal contact, and keeping
  /// them distinct here means `SECURITY.md` never has to fall back on
  /// `contactEmail` for something it isn't.
  static const String securityEmail = 'security@example.com';
}
