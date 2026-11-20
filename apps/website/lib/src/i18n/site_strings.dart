import 'package:website/src/i18n/site_locale.dart';
import 'package:website/src/site_constants.dart';

/// One in-page nav link — anchor [href] plus its visible [label]. Ports
/// the reference site's `Nav.astro` link list, pointed at this single-page
/// site's own sections instead of separate routes ("no extra
/// pages").
///
// This file groups this site's whole copy model together, so its name
// doesn't match this first declaration — same convention as
// core/architecture/mvc/test/mvc_test.dart.
// ignore: solid_lints/prefer_match_file_name
class NavLinkCopy {
  /// Creates a nav link's copy.
  const NavLinkCopy({required this.label, required this.href});

  /// The link's visible text.
  final String label;

  /// The in-page anchor this link points to, e.g. `'#what-you-get'`.
  final String href;
}

/// One step in the hero's "how a project moves" process diagram — ports
/// `Hero.astro`'s `diagramSteps` prop (label + one-word sub-label).
class ProcessStepCopy {
  /// Creates a process step's copy.
  const ProcessStepCopy({required this.label, required this.sub});

  /// The step's short name, e.g. `'Plan'`.
  final String label;

  /// A one-word elaboration shown under the label, e.g. `'scope'`.
  final String sub;
}

/// One feature/service card's copy, for the landing page's bento-style
/// grids (`BentoSection`) — ports the reference site's `BentoSection`/
/// `ServiceCard` structure with neutral placeholder copy. [href]/
/// [linkLabel] are set together for a card that links out (the "what we
/// build" grid); left `null` for a plain card (the "what you get" grid).
class FeatureCardCopy {
  /// Creates a feature card's copy.
  const FeatureCardCopy({
    required this.title,
    required this.description,
    required this.size,
    this.href,
    this.linkLabel,
  });

  /// The card's heading.
  final String title;

  /// One sentence of supporting copy.
  final String description;

  /// The card's grid span — `'hero'` (2x2), `'wide'` (2x1) or `'normal'`
  /// (1x1) — mirrors `ServiceCard.size` in the reference site.
  final String size;

  /// The card's link target, if it is a link card.
  final String? href;

  /// The card's visible link label, if it is a link card.
  final String? linkLabel;
}

/// One step in the landing page's process section (distinct from
/// [ProcessStepCopy], the hero diagram's short label+sub pair) — a
/// numbered step with a full title and a sentence of supporting body
/// copy. Ports the reference site's `.process__step` structure (`index.astro`).
class ProcessStepDetailCopy {
  /// Creates a process step's copy.
  const ProcessStepDetailCopy({required this.title, required this.body});

  /// The step's heading, e.g. `'Scope & Plan'`.
  final String title;

  /// One sentence describing what happens at this step.
  final String body;
}

/// One FAQ entry, for the landing page's FAQ section — a question shown
/// as a `<summary>` and its answer, disclosed on toggle. Ports the
/// reference site's `faqs` array (`index.astro`) and its `<details>`/`<summary>`
/// markup.
class FaqCopy {
  /// Creates a FAQ entry's copy.
  const FaqCopy({required this.question, required this.answer});

  /// The question, shown as the disclosure's always-visible summary.
  final String question;

  /// The answer, shown when the entry is expanded.
  final String answer;
}

/// One proof-point stat, for the landing page's proof section. [countTo],
/// when set, drives the scroll-triggered count-up animation; a stat
/// without it renders its [value] as plain text — mirrors the reference site's
/// stat-card pair (one animated numeric stat, one plain-text
/// stat).
class StatCopy {
  /// Creates a stat's copy.
  const StatCopy({required this.value, required this.label, this.countTo});

  /// The rendered value, e.g. `'250+'` or `'Fully documented'`.
  final String value;

  /// One line describing what the stat measures.
  final String label;

  /// The integer the count-up animation counts up to, if this stat
  /// animates — `value` must still carry the final rendered text (e.g.
  /// `'250+'` for `countTo: 250`), read by assistive tech instead of the
  /// animated, `aria-hidden` counter.
  final int? countTo;
}

/// All of this site's copy, in one locale — a small hand-written
/// dictionary (not a full i18n framework), matching the reference site's own
/// `i18n/chrome.ts` rationale: the copy surface here is small enough that
/// a heavier setup (slang, ARB files) would be pure overhead. Access via
/// [SiteStrings.of].
///
/// Every string here is neutral template-placeholder copy — none of it repeats
/// a sentence of any real site; several of them are deliberately written in a
/// "this explains itself" meta voice (e.g. "This is the hero's supporting
/// paragraph") for the same reason the original placeholder copy already did:
/// whoever clones this template should be in no doubt that it needs replacing.
enum SiteStrings {
  /// English copy.
  _en._(
    skipToContent: 'Skip to content',
    languageSwitcherLabel: 'Language',
    navAriaLabel: 'Section navigation',
    navMenuOpenLabel: 'Open menu',
    navMenuCloseLabel: 'Close menu',
    navCtaLabel: 'Get in touch',
    ctaEmail: 'hello@example.com',
    navLinks: [
      NavLinkCopy(label: 'What you get', href: '#what-you-get'),
      NavLinkCopy(label: 'What we build', href: '#what-we-build'),
      NavLinkCopy(label: 'Proof', href: '#proof'),
      NavLinkCopy(label: 'Process', href: '#process'),
      NavLinkCopy(label: 'FAQ', href: '#faq'),
    ],
    homeTitle: '$productName — a landing page template',
    homeDescription:
        '$productName is a placeholder landing page for a Flutter '
        'monorepo template. Replace every heading and paragraph before '
        'shipping.',
    heroEyebrow: 'Template placeholder',
    heroHeadline: 'This headline sells your product in one line.',
    heroLede:
        "This is the hero's supporting paragraph. Replace it with two "
        'sentences that say what your product does and who it is for — '
        'nothing more is needed here.',
    heroPrimaryCtaLabel: 'Get Started',
    heroSecondaryCtaLabel: 'See what you get →',
    heroNote: 'Replace this note with a real supporting detail, or remove it.',
    heroDiagramLabel:
        'Diagram: a three-step process, Plan then Build then Ship',
    heroDiagramCaption: 'Three steps, start to finish',
    heroDiagramSteps: [
      ProcessStepCopy(label: 'Plan', sub: 'scope'),
      ProcessStepCopy(label: 'Build', sub: 'develop'),
      ProcessStepCopy(label: 'Ship', sub: 'release'),
    ],
    featuresEyebrow: 'What you get',
    featuresHeading: 'What you get',
    features: [
      FeatureCardCopy(
        title: 'Your first, best reason to buy',
        description:
            'This is the card most visitors read first — use it for the '
            'single clearest, most specific benefit of your product.',
        size: 'hero',
      ),
      FeatureCardCopy(
        title: 'A second supporting point',
        description: 'One sentence backing up why this matters.',
        size: 'normal',
      ),
      FeatureCardCopy(
        title: 'A third supporting point',
        description: 'Another sentence, about the same length as the last.',
        size: 'normal',
      ),
      FeatureCardCopy(
        title: 'Room for a longer, fourth point',
        description:
            'This card is wider than the others — use the extra room for '
            'a benefit that needs a little more space to explain.',
        size: 'wide',
      ),
    ],
    servicesEyebrow: 'Explore',
    servicesHeading: 'A closer look',
    services: [
      FeatureCardCopy(
        title: 'Your first offering',
        description:
            'Describe your first product or service line in one clear '
            'sentence, then link out to learn more about it.',
        size: 'wide',
        href: 'mailto:hello@example.com',
        linkLabel: 'Learn more →',
      ),
      FeatureCardCopy(
        title: 'Your second offering',
        description: 'A short description of a second thing you offer.',
        size: 'normal',
        href: 'mailto:hello@example.com',
        linkLabel: 'Learn more →',
      ),
      FeatureCardCopy(
        title: 'Your third offering',
        description: 'A short description of a third thing you offer.',
        size: 'normal',
        href: 'mailto:hello@example.com',
        linkLabel: 'Learn more →',
      ),
      FeatureCardCopy(
        title: 'A fourth, optional offering',
        description: 'Delete this card if you only have three.',
        size: 'normal',
        href: 'mailto:hello@example.com',
        linkLabel: 'Learn more →',
      ),
    ],
    proofBadge: 'In progress',
    proofHeading: 'A real example, not a mockup',
    proofBodyOne:
        'This is where you show your strongest proof — a flagship '
        'project, a live product, or real usage data — instead of just '
        'claiming it. Replace this paragraph with your own.',
    proofBodyTwo:
        'Keep it concrete: what it is, why it backs up what you claim '
        'above, and a link for someone who wants to see more.',
    proofLinkLabel: 'Get in touch →',
    proofStats: [
      StatCopy(
        value: '250+',
        label: 'Placeholder metric — swap for a real number.',
        countTo: 250,
      ),
      StatCopy(
        value: 'Fully documented',
        label: 'A second, non-numeric placeholder metric.',
      ),
    ],
    proofPillsLabel: 'Placeholder tags',
    proofPills: ['Tag one', 'Tag two', 'Tag three', 'Tag four'],
    processEyebrow: 'Process',
    processHeading: 'Four steps, start to finish.',
    processSteps: [
      ProcessStepDetailCopy(
        title: 'Step one',
        body:
            'Describe the first stage of your process — what happens '
            'before any work starts.',
      ),
      ProcessStepDetailCopy(
        title: 'Step two',
        body:
            'What happens once work begins. Keep this concrete, not '
            'aspirational.',
      ),
      ProcessStepDetailCopy(
        title: 'Step three',
        body:
            'How you deliver the result — what "done" looks like for '
            'someone you work with.',
      ),
      ProcessStepDetailCopy(
        title: 'Step four',
        body:
            'What happens after delivery — ongoing support, iteration, '
            'or nothing at all. Delete this step if you only have three.',
      ),
    ],
    faqEyebrow: 'FAQ',
    faqHeading: 'Common questions',
    faqs: [
      FaqCopy(
        question: 'Replace this with your first frequently asked question.',
        answer:
            'Answer it in two or three sentences — long enough to '
            'actually help, short enough that someone skims the whole '
            'list.',
      ),
      FaqCopy(
        question: 'Replace this with your second question.',
        answer:
            'Keep the tone consistent with the rest of the page — this '
            'is still your product talking, not a separate voice.',
      ),
      FaqCopy(
        question: 'What if I only need three questions, not four?',
        answer: 'Delete this card. Four is a starting point, not a rule.',
      ),
      FaqCopy(
        question: 'Where does this copy come from?',
        answer:
            'Nowhere real — every question and answer here is a '
            'placeholder. Replace all four before shipping.',
      ),
    ],
    ctaHeading: 'Ready to see this working end to end?',
    ctaBody: 'Replace this line with your own closing pitch.',
    ctaLabel: 'Start a Conversation',
    footerCompanyHeading: 'Company',
    footerLegalHeading: 'Legal',
    footerConnectHeading: 'Connect',
    footerImpressumLabel: 'Impressum',
    footerDatenschutzLabel: 'Privacy Policy',
    footerEmailAccessiblePrefix: 'Email',
    footerCopyright: '© {year} $productName. All rights reserved.',
    notFoundTitle: '404 — $productName',
    notFoundDescription: "This page doesn't exist. Head back home.",
    notFoundHeading: "This page doesn't exist.",
    notFoundBody: 'You followed a broken link, or the page moved.',
    notFoundLinkLabel: 'Back to home',
  ),

  /// German copy.
  _de._(
    skipToContent: 'Zum Inhalt springen',
    languageSwitcherLabel: 'Sprache',
    navAriaLabel: 'Abschnittsnavigation',
    navMenuOpenLabel: 'Menü öffnen',
    navMenuCloseLabel: 'Menü schließen',
    navCtaLabel: 'Kontakt aufnehmen',
    ctaEmail: 'hello@example.com',
    navLinks: [
      NavLinkCopy(label: 'Was Sie bekommen', href: '#what-you-get'),
      NavLinkCopy(label: 'Was wir bauen', href: '#what-we-build'),
      NavLinkCopy(label: 'Nachweis', href: '#proof'),
      NavLinkCopy(label: 'Ablauf', href: '#process'),
      NavLinkCopy(label: 'FAQ', href: '#faq'),
    ],
    homeTitle: '$productName — eine Landingpage-Vorlage',
    homeDescription:
        '$productName ist eine Platzhalter-Landingpage für eine '
        'Flutter-Monorepo-Vorlage. Ersetzen Sie jede Überschrift und '
        'jeden Absatz vor dem Livegang.',
    heroEyebrow: 'Platzhalter der Vorlage',
    heroHeadline: 'Diese Überschrift verkauft Ihr Produkt in einem Satz.',
    heroLede:
        'Dies ist der unterstützende Absatz der Hero-Sektion. Ersetzen '
        'Sie ihn durch zwei Sätze, die sagen, was Ihr Produkt tut und '
        'für wen es ist — mehr braucht es hier nicht.',
    heroPrimaryCtaLabel: 'Jetzt starten',
    heroSecondaryCtaLabel: 'Was Sie bekommen →',
    heroNote:
        'Ersetzen Sie diesen Hinweis durch echten Inhalt oder '
        'entfernen Sie ihn.',
    heroDiagramLabel:
        'Diagramm: ein dreistufiger Prozess, Planen, dann Bauen, dann '
        'Liefern',
    heroDiagramCaption: 'Drei Schritte, von Anfang bis Ende',
    heroDiagramSteps: [
      ProcessStepCopy(label: 'Planen', sub: 'Umfang'),
      ProcessStepCopy(label: 'Bauen', sub: 'Entwicklung'),
      ProcessStepCopy(label: 'Liefern', sub: 'Release'),
    ],
    featuresEyebrow: 'Was Sie bekommen',
    featuresHeading: 'Was Sie bekommen',
    features: [
      FeatureCardCopy(
        title: 'Ihr erster, bester Kaufgrund',
        description:
            'Diese Karte lesen die meisten Besucher zuerst — nutzen Sie '
            'sie für den klarsten, konkretesten Vorteil Ihres Produkts.',
        size: 'hero',
      ),
      FeatureCardCopy(
        title: 'Ein zweiter unterstützender Punkt',
        description: 'Ein Satz, der begründet, warum das wichtig ist.',
        size: 'normal',
      ),
      FeatureCardCopy(
        title: 'Ein dritter unterstützender Punkt',
        description: 'Ein weiterer Satz, etwa so lang wie der letzte.',
        size: 'normal',
      ),
      FeatureCardCopy(
        title: 'Platz für einen vierten, längeren Punkt',
        description:
            'Diese Karte ist breiter als die anderen — nutzen Sie den '
            'zusätzlichen Platz für einen Vorteil, der mehr Erklärung '
            'braucht.',
        size: 'wide',
      ),
    ],
    servicesEyebrow: 'Entdecken',
    servicesHeading: 'Ein genauerer Blick',
    services: [
      FeatureCardCopy(
        title: 'Ihr erstes Angebot',
        description:
            'Beschreiben Sie Ihr erstes Produkt oder Ihre erste '
            'Dienstleistung in einem klaren Satz und verlinken Sie zu '
            'weiteren Details.',
        size: 'wide',
        href: 'mailto:hello@example.com',
        linkLabel: 'Mehr erfahren →',
      ),
      FeatureCardCopy(
        title: 'Ihr zweites Angebot',
        description: 'Eine kurze Beschreibung eines zweiten Angebots.',
        size: 'normal',
        href: 'mailto:hello@example.com',
        linkLabel: 'Mehr erfahren →',
      ),
      FeatureCardCopy(
        title: 'Ihr drittes Angebot',
        description: 'Eine kurze Beschreibung eines dritten Angebots.',
        size: 'normal',
        href: 'mailto:hello@example.com',
        linkLabel: 'Mehr erfahren →',
      ),
      FeatureCardCopy(
        title: 'Ein viertes, optionales Angebot',
        description: 'Löschen Sie diese Karte, falls Sie nur drei haben.',
        size: 'normal',
        href: 'mailto:hello@example.com',
        linkLabel: 'Mehr erfahren →',
      ),
    ],
    proofBadge: 'In Arbeit',
    proofHeading: 'Ein echtes Beispiel, kein Mockup',
    proofBodyOne:
        'Hier zeigen Sie Ihren stärksten Nachweis — ein Vorzeigeprojekt, '
        'ein laufendes Produkt oder echte Nutzungsdaten — statt es nur '
        'zu behaupten. Ersetzen Sie diesen Absatz durch Ihren eigenen.',
    proofBodyTwo:
        'Bleiben Sie konkret: was es ist, warum es Ihre Aussage oben '
        'stützt, und ein Link für alle, die mehr sehen wollen.',
    proofLinkLabel: 'Kontakt aufnehmen →',
    proofStats: [
      StatCopy(
        value: '250+',
        label: 'Platzhalterkennzahl — durch eine echte Zahl ersetzen.',
        countTo: 250,
      ),
      StatCopy(
        value: 'Vollständig dokumentiert',
        label: 'Eine zweite, nicht-numerische Platzhalterkennzahl.',
      ),
    ],
    proofPillsLabel: 'Platzhalter-Tags',
    proofPills: ['Tag eins', 'Tag zwei', 'Tag drei', 'Tag vier'],
    processEyebrow: 'Ablauf',
    processHeading: 'Vier Schritte, von Anfang bis Ende.',
    processSteps: [
      ProcessStepDetailCopy(
        title: 'Schritt eins',
        body:
            'Beschreiben Sie die erste Phase Ihres Prozesses — was '
            'passiert, bevor irgendeine Arbeit beginnt.',
      ),
      ProcessStepDetailCopy(
        title: 'Schritt zwei',
        body:
            'Was passiert, sobald die Arbeit beginnt. Bleiben Sie '
            'konkret, nicht ambitioniert-vage.',
      ),
      ProcessStepDetailCopy(
        title: 'Schritt drei',
        body:
            'Wie Sie das Ergebnis liefern — wie „fertig“ für jemanden '
            'aussieht, mit dem Sie zusammenarbeiten.',
      ),
      ProcessStepDetailCopy(
        title: 'Schritt vier',
        body:
            'Was nach der Lieferung passiert — laufender Support, '
            'Weiterentwicklung, oder gar nichts. Löschen Sie diesen '
            'Schritt, falls Sie nur drei haben.',
      ),
    ],
    faqEyebrow: 'FAQ',
    faqHeading: 'Häufige Fragen',
    faqs: [
      FaqCopy(
        question: 'Ersetzen Sie dies durch Ihre erste häufig gestellte Frage.',
        answer:
            'Beantworten Sie sie in zwei bis drei Sätzen — lang genug, '
            'um wirklich zu helfen, kurz genug, dass jemand die ganze '
            'Liste überfliegen kann.',
      ),
      FaqCopy(
        question: 'Ersetzen Sie dies durch Ihre zweite Frage.',
        answer:
            'Halten Sie den Ton konsistent mit dem Rest der Seite — es '
            'spricht weiterhin Ihr Produkt, nicht eine andere Stimme.',
      ),
      FaqCopy(
        question: 'Was, wenn ich nur drei Fragen brauche, nicht vier?',
        answer:
            'Löschen Sie diese Karte. Vier ist ein Ausgangspunkt, keine '
            'Regel.',
      ),
      FaqCopy(
        question: 'Woher kommt dieser Text?',
        answer:
            'Von nirgendwo Echtem — jede Frage und Antwort hier ist ein '
            'Platzhalter. Ersetzen Sie alle vier vor dem Livegang.',
      ),
    ],
    ctaHeading: 'Bereit, das einmal ganz zu sehen?',
    ctaBody: 'Ersetzen Sie diese Zeile durch Ihren eigenen Schlusssatz.',
    ctaLabel: 'Gespräch starten',
    footerCompanyHeading: 'Unternehmen',
    footerLegalHeading: 'Rechtliches',
    footerConnectHeading: 'Kontakt',
    footerImpressumLabel: 'Impressum',
    footerDatenschutzLabel: 'Datenschutzerklärung',
    footerEmailAccessiblePrefix: 'E-Mail',
    footerCopyright: '© {year} $productName. Alle Rechte vorbehalten.',
    notFoundTitle: '404 — $productName',
    notFoundDescription:
        'Diese Seite existiert nicht. Zurück zur '
        'Startseite.',
    notFoundHeading: 'Diese Seite existiert nicht.',
    notFoundBody:
        'Der Link ist fehlerhaft, oder die Seite wurde '
        'verschoben.',
    notFoundLinkLabel: 'Zurück zur Startseite',
  );

  SiteStrings._({
    required this.skipToContent,
    required this.languageSwitcherLabel,
    required this.navAriaLabel,
    required this.navMenuOpenLabel,
    required this.navMenuCloseLabel,
    required this.navCtaLabel,
    required this.ctaEmail,
    required this.navLinks,
    required this.homeTitle,
    required this.homeDescription,
    required this.heroEyebrow,
    required this.heroHeadline,
    required this.heroLede,
    required this.heroPrimaryCtaLabel,
    required this.heroSecondaryCtaLabel,
    required this.heroNote,
    required this.heroDiagramLabel,
    required this.heroDiagramCaption,
    required this.heroDiagramSteps,
    required this.featuresEyebrow,
    required this.featuresHeading,
    required this.features,
    required this.servicesEyebrow,
    required this.servicesHeading,
    required this.services,
    required this.proofBadge,
    required this.proofHeading,
    required this.proofBodyOne,
    required this.proofBodyTwo,
    required this.proofLinkLabel,
    required this.proofStats,
    required this.proofPillsLabel,
    required this.proofPills,
    required this.processEyebrow,
    required this.processHeading,
    required this.processSteps,
    required this.faqEyebrow,
    required this.faqHeading,
    required this.faqs,
    required this.ctaHeading,
    required this.ctaBody,
    required this.ctaLabel,
    required this.footerCompanyHeading,
    required this.footerLegalHeading,
    required this.footerConnectHeading,
    required this.footerImpressumLabel,
    required this.footerDatenschutzLabel,
    required this.footerEmailAccessiblePrefix,
    required this.footerCopyright,
    required this.notFoundTitle,
    required this.notFoundDescription,
    required this.notFoundHeading,
    required this.notFoundBody,
    required this.notFoundLinkLabel,
  });

  /// Returns the copy for [locale].
  static SiteStrings of(SiteLocale locale) =>
      locale == SiteLocale.en ? _en : _de;

  /// Accessible label for the skip-to-content link, the first focusable
  /// element on every page.
  final String skipToContent;

  /// `<nav aria-label>` for the language switcher.
  final String languageSwitcherLabel;

  /// `aria-label` for the nav's in-page section links, shared by the
  /// inline `<nav>` and the mobile menu overlay's own copy of the same
  /// links.
  final String navAriaLabel;

  /// Accessible label for the mobile nav toggle button in its closed
  /// (menu-hidden) state.
  final String navMenuOpenLabel;

  /// Accessible label for the mobile nav overlay's own close button, and
  /// for the toggle button once the overlay is open.
  final String navMenuCloseLabel;

  /// The nav bar's primary CTA label.
  final String navCtaLabel;

  /// Placeholder contact address the nav/CTA `mailto:` links use — not a
  /// legal fact (see `LegalFacts.contactEmail` for that), just a
  /// generic "get in touch" address.
  final String ctaEmail;

  /// The nav bar's in-page section links.
  final List<NavLinkCopy> navLinks;

  /// The home page's `<title>`.
  final String homeTitle;

  /// The home page's meta description.
  final String homeDescription;

  /// Hero eyebrow (small label above the headline).
  final String heroEyebrow;

  /// Hero `<h1>`.
  final String heroHeadline;

  /// Hero supporting paragraph.
  final String heroLede;

  /// Hero primary CTA label.
  final String heroPrimaryCtaLabel;

  /// Hero secondary CTA label.
  final String heroSecondaryCtaLabel;

  /// Small supporting note under the hero CTAs.
  final String heroNote;

  /// Accessible label for the hero's process diagram (`role="img"`).
  final String heroDiagramLabel;

  /// The process diagram's small caption.
  final String heroDiagramCaption;

  /// The process diagram's steps, in order.
  final List<ProcessStepCopy> heroDiagramSteps;

  /// "What you get" bento-grid section eyebrow.
  final String featuresEyebrow;

  /// "What you get" bento-grid section heading.
  final String featuresHeading;

  /// The "what you get" grid's cards (no links).
  final List<FeatureCardCopy> features;

  /// "What we build" grid section eyebrow.
  final String servicesEyebrow;

  /// "What we build" grid section heading.
  final String servicesHeading;

  /// The "what we build" grid's cards (each links out).
  final List<FeatureCardCopy> services;

  /// The proof section's status badge text.
  final String proofBadge;

  /// The proof section's heading.
  final String proofHeading;

  /// The proof section's first paragraph.
  final String proofBodyOne;

  /// The proof section's second paragraph.
  final String proofBodyTwo;

  /// The proof section's link label.
  final String proofLinkLabel;

  /// The proof section's stat cards.
  final List<StatCopy> proofStats;

  /// Accessible `aria-label` for the proof section's tag-pill list.
  final String proofPillsLabel;

  /// The proof section's short tag pills.
  final List<String> proofPills;

  /// The process section's eyebrow.
  final String processEyebrow;

  /// The process section's heading.
  final String processHeading;

  /// The process section's numbered steps, in order.
  final List<ProcessStepDetailCopy> processSteps;

  /// The FAQ section's eyebrow.
  final String faqEyebrow;

  /// The FAQ section's heading.
  final String faqHeading;

  /// The FAQ section's entries, in order.
  final List<FaqCopy> faqs;

  /// Final CTA band heading.
  final String ctaHeading;

  /// Final CTA band supporting line.
  final String ctaBody;

  /// Final CTA band button label.
  final String ctaLabel;

  /// Footer "Company" column heading.
  final String footerCompanyHeading;

  /// Footer "Legal" column heading.
  final String footerLegalHeading;

  /// Footer "Connect" column heading.
  final String footerConnectHeading;

  /// Footer link label for the Impressum page.
  final String footerImpressumLabel;

  /// Footer link label for the Datenschutz page.
  final String footerDatenschutzLabel;

  /// Accessible-name prefix for the footer's `mailto:` link.
  final String footerEmailAccessiblePrefix;

  /// Footer copyright line, with a literal `{year}` placeholder the
  /// footer component substitutes at render time.
  final String footerCopyright;

  /// The 404 page's `<title>`.
  final String notFoundTitle;

  /// The 404 page's meta description.
  final String notFoundDescription;

  /// The 404 page's `<h1>`.
  final String notFoundHeading;

  /// The 404 page's body copy.
  final String notFoundBody;

  /// The 404 page's "back to home" link label.
  final String notFoundLinkLabel;
}
