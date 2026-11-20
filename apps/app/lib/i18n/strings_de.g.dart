///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsDe extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsDe({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.de,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <de>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsDe _root = this; // ignore: unused_field

	@override 
	TranslationsDe $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsDe(meta: meta ?? this.$meta);

	// Translations
	@override String get appTitle => 'flutter_template';
	@override late final _Translations$common$de common = _Translations$common$de._(_root);
	@override late final _Translations$bootstrap$de bootstrap = _Translations$bootstrap$de._(_root);
	@override late final _Translations$consent$de consent = _Translations$consent$de._(_root);
	@override late final _Translations$signIn$de signIn = _Translations$signIn$de._(_root);
	@override late final _Translations$onboarding$de onboarding = _Translations$onboarding$de._(_root);
	@override late final _Translations$permissionPrePrompt$de permissionPrePrompt = _Translations$permissionPrePrompt$de._(_root);
	@override late final _Translations$home$de home = _Translations$home$de._(_root);
	@override late final _Translations$settings$de settings = _Translations$settings$de._(_root);
	@override late final _Translations$legal$de legal = _Translations$legal$de._(_root);
}

// Path: common
class _Translations$common$de extends Translations$common$en {
	_Translations$common$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Abbrechen';
	@override String get close => 'Schließen';
	@override String get back => 'Zurück';
	@override String get continueLabel => 'Weiter';
	@override String get notNow => 'Nicht jetzt';
	@override String get legalLink => 'Rechtliches';
	@override String get agbLink => 'AGB';
	@override String get datenschutzLink => 'Datenschutzerklärung';
	@override String get orDivider => 'oder';
}

// Path: bootstrap
class _Translations$bootstrap$de extends Translations$bootstrap$en {
	_Translations$bootstrap$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get checkingVersion => 'Suche nach Updates…';
	@override String get blockedTitle => 'Update erforderlich';
	@override String get blockedMessage => 'Diese App-Version wird nicht mehr unterstützt. Bitte aktualisiere die App, um fortzufahren.';
	@override String get updateButton => 'Jetzt aktualisieren';
}

// Path: consent
class _Translations$consent$de extends Translations$consent$en {
	_Translations$consent$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get eyebrowLabel => 'Einwilligung';
	@override String get title => 'Bevor es weitergeht';
	@override String get message => 'Wir möchten Analysedaten nutzen, um diese App zu verbessern. Du kannst deine Wahl jederzeit in Einstellungen → Datenschutz ändern.';
	@override String get accept => 'Akzeptieren';
	@override String get reject => 'Ablehnen';
	@override String get settingsLink => 'In den Einstellungen verwalten';
}

// Path: signIn
class _Translations$signIn$de extends Translations$signIn$en {
	_Translations$signIn$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Anmelden';
	@override String get emailLabel => 'E-Mail-Adresse';
	@override String get requestCodeButton => 'Code senden';
	@override String get codeLabel => '6-stelliger Code';
	@override String codeHint({required Object email}) => 'Gib den Code ein, den wir an ${email} gesendet haben';
	@override String get verifyButton => 'Bestätigen';
	@override String get changeEmailButton => 'Andere E-Mail-Adresse verwenden';
	@override String get resendCodeButton => 'Code erneut senden';
	@override String get passkeyButton => 'Mit Passkey anmelden';
	@override String get appleButton => 'Mit Apple anmelden';
	@override String get googleButton => 'Mit Google anmelden';
	@override String get reviewerButton => 'Als App-Review-Demokonto fortfahren';
	@override String get reviewCodeHint => 'Gib den Review-Code aus den Store-Review-Hinweisen ein';
	@override String get reviewCodeLabel => 'Review-Code';
	@override String get reviewerSubmitButton => 'Als Reviewer anmelden';
	@override String get errorGeneric => 'Etwas ist schiefgelaufen. Bitte versuche es erneut.';
	@override String get errorInvalidCode => 'Der Code ist nicht korrekt. Bitte versuche es erneut.';
	@override String get errorRateLimited => 'Zu viele Versuche. Bitte warte einen Moment und versuche es erneut.';
}

// Path: onboarding
class _Translations$onboarding$de extends Translations$onboarding$en {
	_Translations$onboarding$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String stepProgress({required Object current, required Object total}) => 'Schritt ${current} von ${total}';
	@override String get nextButton => 'Weiter';
	@override String get skipForNow => 'Später überspringen';
	@override String get savedHint => 'Gespeichert';
	@override String get stepProfileTitle => 'Profil';
	@override String get stepProfileDisplayNameLabel => 'Anzeigename';
	@override String get stepProfileAddPhotoButton => 'Foto hinzufügen';
	@override String get stepPreferencesTitle => 'Präferenzen';
	@override String stepPreferencesQuestion({required Object appName}) => 'Wie möchtest du ${appName} nutzen?';
	@override String get stepPreferencesOptionPersonalTitle => 'Privat';
	@override String get stepPreferencesOptionPersonalHint => 'Nur für dich';
	@override String get stepPreferencesOptionWorkTitle => 'Arbeit / Team';
	@override String get stepPreferencesOptionWorkHint => 'Gemeinsam mit Kolleg:innen';
	@override String get stepPreferencesOptionExploringTitle => 'Nur zum Ausprobieren';
	@override String get stepPreferencesOptionExploringHint => 'Noch nicht sicher';
	@override String get stepNotificationsTitle => 'Benachrichtigungen';
}

// Path: permissionPrePrompt
class _Translations$permissionPrePrompt$de extends Translations$permissionPrePrompt$en {
	_Translations$permissionPrePrompt$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get pushTitle => 'Bleib auf dem Laufenden';
	@override String get pushMessage => 'Wenn du Benachrichtigungen aktivierst, informieren wir dich über Dinge, die für dich wichtig sind. Du kannst dies später in den Geräteeinstellungen ändern.';
	@override String get attTitle => 'Hilf uns, diese App kostenlos zu halten';
	@override String get attMessage => 'Wenn du Tracking erlaubst, können wir dir relevantere Inhalte zeigen. Du kannst dies später in den Geräteeinstellungen ändern.';
	@override String get locationTitle => 'Standort verwenden';
	@override String get locationMessage => 'Wenn du deinen Standort teilst, können wir die App darauf abstimmen. Du kannst dies später in den Geräteeinstellungen ändern.';
}

// Path: home
class _Translations$home$de extends Translations$home$en {
	_Translations$home$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Start';
	@override String get emptyStateMessage => 'Hier ist noch nichts los — hier erscheinen später deine Inhalte.';
	@override String get settingsButton => 'Einstellungen';
	@override String get signOutButton => 'Abmelden';
	@override String get setupCardTitle => 'Einrichtung abschließen';
	@override String setupCardProgress({required Object completed, required Object total}) => '${completed} von ${total} erledigt';
	@override String get setupCardDismiss => 'Schließen';
}

// Path: settings
class _Translations$settings$de extends Translations$settings$en {
	_Translations$settings$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Einstellungen';
	@override String get legalLink => 'Rechtliches';
	@override String get privacyLink => 'Datenschutz';
	@override String get accountLink => 'Konto';
	@override String get teamsLink => 'Teams';
	@override String get paywallLink => 'Abonnement';
	@override late final _Translations$settings$account$de account = _Translations$settings$account$de._(_root);
	@override late final _Translations$settings$privacy$de privacy = _Translations$settings$privacy$de._(_root);
	@override late final _Translations$settings$paywall$de paywall = _Translations$settings$paywall$de._(_root);
	@override late final _Translations$settings$teams$de teams = _Translations$settings$teams$de._(_root);
}

// Path: legal
class _Translations$legal$de extends Translations$legal$en {
	_Translations$legal$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Rechtliches';
	@override String get impressum => 'Impressum';
	@override String get datenschutz => 'Datenschutzerklärung';
	@override String get agb => 'AGB';
	@override String get barrierefreiheit => 'Barrierefreiheit';
	@override String get licencesLink => 'Open-Source-Lizenzen';
	@override late final _Translations$legal$document$de document = _Translations$legal$document$de._(_root);
	@override late final _Translations$legal$licences$de licences = _Translations$legal$licences$de._(_root);
}

// Path: settings.account
class _Translations$settings$account$de extends Translations$settings$account$en {
	_Translations$settings$account$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Konto';
	@override String get linkedIdentitiesTitle => 'Verknüpfte Konten';
	@override String get noLinkedIdentities => 'Es sind keine Social-Konten verknüpft.';
	@override String get disconnectButton => 'Trennen';
	@override String get dangerZoneLabel => 'Gefahrenzone';
	@override String get deleteAccountButton => 'Konto löschen';
	@override String get deleteConfirmTitle => 'Konto löschen?';
	@override String get deleteConfirmMessage => 'Dies löscht dein Konto und alle zugehörigen Daten dauerhaft. Dies kann nicht rückgängig gemacht werden.';
	@override String get deleteConfirmButton => 'Löschen';
	@override String get deleteCancelButton => 'Abbrechen';
	@override String deleteOwnsTeams({required Object teams}) => 'Du bist Eigentümer von ${teams}. Übertrage die Inhaberschaft an ein anderes Mitglied oder lösche das Team unter Einstellungen > Teams, bevor du dein Konto löschst.';
	@override String get deleteFailed => 'Dein Konto konnte nicht gelöscht werden. Bitte versuche es erneut.';
}

// Path: settings.privacy
class _Translations$settings$privacy$de extends Translations$settings$privacy$en {
	_Translations$settings$privacy$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Datenschutz';
	@override String get consentSectionTitle => 'Einwilligung';
	@override String get consentStatusAccepted => 'Du hast Analyse-Tracking akzeptiert.';
	@override String get consentStatusRejected => 'Du hast Analyse-Tracking abgelehnt.';
	@override String get consentStatusNotSet => 'Du hast noch keine Wahl getroffen.';
	@override String get changeConsentAccept => 'Akzeptieren';
	@override String get changeConsentReject => 'Ablehnen';
	@override String get consentChipAccepted => 'Akzeptiert';
	@override String get consentChipRejected => 'Abgelehnt';
	@override String get consentChipNotSet => 'Nicht festgelegt';
	@override String get exportTitle => 'Deine Daten exportieren';
	@override String get exportDescription => 'Lade eine Kopie der mit deinem Konto verknüpften Daten im JSON-Format herunter.';
	@override String get exportButton => 'Meine Daten exportieren';
	@override String get exportStepUpTitle => 'Bestätige, dass du es bist';
	@override String get exportStepUpMessage => 'Zu deiner Sicherheit bestätige bitte deine E-Mail-Adresse erneut, bevor wir deine Daten exportieren.';
	@override String get exportCodeLabel => '6-stelliger Code';
	@override String get exportVerifyButton => 'Bestätigen und exportieren';
	@override String get exportResultTitle => 'Deine Daten';
	@override String get exportCopyButton => 'Kopieren';
}

// Path: settings.paywall
class _Translations$settings$paywall$de extends Translations$settings$paywall$en {
	_Translations$settings$paywall$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Abonnement';
	@override String get statusNone => 'Kein Abonnement';
	@override String get statusActive => 'Aktiv';
	@override String get statusTrialing => 'Testphase';
	@override String get statusPastDue => 'Zahlung fehlgeschlagen, der Zugang bleibt vorerst bestehen';
	@override String get statusExpired => 'Zahlung fehlgeschlagen, der Zugang ist beendet';
	@override String get statusPaused => 'Pausiert';
	@override String get statusCanceled => 'Gekündigt';
	@override String quantityValue({required Object count}) => '${count} Einheiten';
	@override String renewsOn({required Object date}) => 'Verlängert sich am ${date}';
	@override String cancelsOn({required Object date}) => 'Endet am ${date}';
	@override String graceEndsOn({required Object date}) => 'Aktualisiere deine Zahlungsmethode vor dem ${date}';
	@override String get quantityLabel => 'Einheiten';
	@override String get increaseLabel => 'Eine Einheit mehr';
	@override String get decreaseLabel => 'Eine Einheit weniger';
	@override String get subscribeButton => 'Abonnieren';
	@override String get applyQuantityButton => 'Einheiten ändern (anteilig)';
	@override String get manageButton => 'Abrechnung verwalten';
	@override String get refreshButton => 'Ich habe bezahlt, aktualisieren';
	@override String get failed => 'Das hat nicht geklappt. Versuche es gleich noch einmal.';
	@override String get signedOut => 'Melde dich an, um dein Abonnement zu verwalten.';
}

// Path: settings.teams
class _Translations$settings$teams$de extends Translations$settings$teams$en {
	_Translations$settings$teams$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Teams';
	@override String get noTeams => 'Du bist noch in keinem Team.';
	@override String get activeChip => 'Aktives Team';
	@override String get switchButton => 'Wechseln';
	@override String get membersButton => 'Mitglieder';
	@override String get invitationsTitle => 'Einladungen';
	@override String invitationRole({required Object role}) => 'Eingeladen als ${role}';
	@override String get acceptButton => 'Annehmen';
	@override String get createTitle => 'Team erstellen';
	@override String get nameLabel => 'Teamname';
	@override String get createButton => 'Team erstellen';
	@override String get failed => 'Das hat nicht geklappt. Prüfe deine Verbindung und Berechtigungen und versuche es erneut.';
	@override late final _Translations$settings$teams$members$de members = _Translations$settings$teams$members$de._(_root);
}

// Path: legal.document
class _Translations$legal$document$de extends Translations$legal$document$en {
	_Translations$legal$document$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get templateNotice => 'PLATZHALTERTEXT — vor Veröffentlichung durch anwaltlich geprüften Text ersetzen.';
	@override String get impressumIntro => 'Angaben gemäß § 5 DDG:';
	@override String get datenschutzIntro => 'Dies ist eine Platzhalter-Datenschutzerklärung. Ersetze sie durch eine DSGVO-Art.-13-konforme Erklärung, die beschreibt, welche Daten diese App tatsächlich erhebt und warum.';
	@override String get agbIntro => 'Dies sind Platzhalter-Allgemeine-Geschäftsbedingungen.';
	@override String get barrierefreiheitIntro => 'Dies ist eine Platzhalter-Erklärung zur Barrierefreiheit.';
	@override String get factCompanyName => 'Unternehmen';
	@override String get factAddress => 'Anschrift';
	@override String get factRegister => 'Registereintrag';
	@override String get factVatId => 'USt-IdNr.';
	@override String get factContactEmail => 'Kontakt';
	@override String get factResponsiblePerson => 'Verantwortlich für den Inhalt (§ 18 Abs. 2 MStV)';
	@override String get factSupervisoryAuthority => 'Aufsichtsbehörde';
}

// Path: legal.licences
class _Translations$legal$licences$de extends Translations$legal$licences$en {
	_Translations$legal$licences$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Open-Source-Lizenzen';
	@override String get copyButton => 'Kopieren';
	@override String get empty => 'Es wurden keine Lizenzen von Drittanbietern gefunden.';
}

// Path: settings.teams.members
class _Translations$settings$teams$members$de extends Translations$settings$teams$members$en {
	_Translations$settings$teams$members$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Mitglieder';
	@override String get noActiveTeam => 'Erstelle oder wähle zuerst ein Team.';
	@override String get roleOwner => 'Inhaber';
	@override String get roleAdmin => 'Admin';
	@override String get roleMember => 'Mitglied';
	@override String get inviteTitle => 'Jemanden einladen';
	@override String get emailLabel => 'E-Mail-Adresse';
	@override String get inviteButton => 'Einladung senden';
	@override String get pendingTitle => 'Offene Einladungen';
	@override String pendingExpires({required Object date}) => 'Läuft ab am ${date}';
	@override String get revokeButton => 'Zurückziehen';
	@override String get leaveButton => 'Team verlassen';
}

/// The flat map containing all translations for locale <de>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsDe {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appTitle' => 'flutter_template',
			'common.cancel' => 'Abbrechen',
			'common.close' => 'Schließen',
			'common.back' => 'Zurück',
			'common.continueLabel' => 'Weiter',
			'common.notNow' => 'Nicht jetzt',
			'common.legalLink' => 'Rechtliches',
			'common.agbLink' => 'AGB',
			'common.datenschutzLink' => 'Datenschutzerklärung',
			'common.orDivider' => 'oder',
			'bootstrap.checkingVersion' => 'Suche nach Updates…',
			'bootstrap.blockedTitle' => 'Update erforderlich',
			'bootstrap.blockedMessage' => 'Diese App-Version wird nicht mehr unterstützt. Bitte aktualisiere die App, um fortzufahren.',
			'bootstrap.updateButton' => 'Jetzt aktualisieren',
			'consent.eyebrowLabel' => 'Einwilligung',
			'consent.title' => 'Bevor es weitergeht',
			'consent.message' => 'Wir möchten Analysedaten nutzen, um diese App zu verbessern. Du kannst deine Wahl jederzeit in Einstellungen → Datenschutz ändern.',
			'consent.accept' => 'Akzeptieren',
			'consent.reject' => 'Ablehnen',
			'consent.settingsLink' => 'In den Einstellungen verwalten',
			'signIn.title' => 'Anmelden',
			'signIn.emailLabel' => 'E-Mail-Adresse',
			'signIn.requestCodeButton' => 'Code senden',
			'signIn.codeLabel' => '6-stelliger Code',
			'signIn.codeHint' => ({required Object email}) => 'Gib den Code ein, den wir an ${email} gesendet haben',
			'signIn.verifyButton' => 'Bestätigen',
			'signIn.changeEmailButton' => 'Andere E-Mail-Adresse verwenden',
			'signIn.resendCodeButton' => 'Code erneut senden',
			'signIn.passkeyButton' => 'Mit Passkey anmelden',
			'signIn.appleButton' => 'Mit Apple anmelden',
			'signIn.googleButton' => 'Mit Google anmelden',
			'signIn.reviewerButton' => 'Als App-Review-Demokonto fortfahren',
			'signIn.reviewCodeHint' => 'Gib den Review-Code aus den Store-Review-Hinweisen ein',
			'signIn.reviewCodeLabel' => 'Review-Code',
			'signIn.reviewerSubmitButton' => 'Als Reviewer anmelden',
			'signIn.errorGeneric' => 'Etwas ist schiefgelaufen. Bitte versuche es erneut.',
			'signIn.errorInvalidCode' => 'Der Code ist nicht korrekt. Bitte versuche es erneut.',
			'signIn.errorRateLimited' => 'Zu viele Versuche. Bitte warte einen Moment und versuche es erneut.',
			'onboarding.stepProgress' => ({required Object current, required Object total}) => 'Schritt ${current} von ${total}',
			'onboarding.nextButton' => 'Weiter',
			'onboarding.skipForNow' => 'Später überspringen',
			'onboarding.savedHint' => 'Gespeichert',
			'onboarding.stepProfileTitle' => 'Profil',
			'onboarding.stepProfileDisplayNameLabel' => 'Anzeigename',
			'onboarding.stepProfileAddPhotoButton' => 'Foto hinzufügen',
			'onboarding.stepPreferencesTitle' => 'Präferenzen',
			'onboarding.stepPreferencesQuestion' => ({required Object appName}) => 'Wie möchtest du ${appName} nutzen?',
			'onboarding.stepPreferencesOptionPersonalTitle' => 'Privat',
			'onboarding.stepPreferencesOptionPersonalHint' => 'Nur für dich',
			'onboarding.stepPreferencesOptionWorkTitle' => 'Arbeit / Team',
			'onboarding.stepPreferencesOptionWorkHint' => 'Gemeinsam mit Kolleg:innen',
			'onboarding.stepPreferencesOptionExploringTitle' => 'Nur zum Ausprobieren',
			'onboarding.stepPreferencesOptionExploringHint' => 'Noch nicht sicher',
			'onboarding.stepNotificationsTitle' => 'Benachrichtigungen',
			'permissionPrePrompt.pushTitle' => 'Bleib auf dem Laufenden',
			'permissionPrePrompt.pushMessage' => 'Wenn du Benachrichtigungen aktivierst, informieren wir dich über Dinge, die für dich wichtig sind. Du kannst dies später in den Geräteeinstellungen ändern.',
			'permissionPrePrompt.attTitle' => 'Hilf uns, diese App kostenlos zu halten',
			'permissionPrePrompt.attMessage' => 'Wenn du Tracking erlaubst, können wir dir relevantere Inhalte zeigen. Du kannst dies später in den Geräteeinstellungen ändern.',
			'permissionPrePrompt.locationTitle' => 'Standort verwenden',
			'permissionPrePrompt.locationMessage' => 'Wenn du deinen Standort teilst, können wir die App darauf abstimmen. Du kannst dies später in den Geräteeinstellungen ändern.',
			'home.title' => 'Start',
			'home.emptyStateMessage' => 'Hier ist noch nichts los — hier erscheinen später deine Inhalte.',
			'home.settingsButton' => 'Einstellungen',
			'home.signOutButton' => 'Abmelden',
			'home.setupCardTitle' => 'Einrichtung abschließen',
			'home.setupCardProgress' => ({required Object completed, required Object total}) => '${completed} von ${total} erledigt',
			'home.setupCardDismiss' => 'Schließen',
			'settings.title' => 'Einstellungen',
			'settings.legalLink' => 'Rechtliches',
			'settings.privacyLink' => 'Datenschutz',
			'settings.accountLink' => 'Konto',
			'settings.teamsLink' => 'Teams',
			'settings.paywallLink' => 'Abonnement',
			'settings.account.title' => 'Konto',
			'settings.account.linkedIdentitiesTitle' => 'Verknüpfte Konten',
			'settings.account.noLinkedIdentities' => 'Es sind keine Social-Konten verknüpft.',
			'settings.account.disconnectButton' => 'Trennen',
			'settings.account.dangerZoneLabel' => 'Gefahrenzone',
			'settings.account.deleteAccountButton' => 'Konto löschen',
			'settings.account.deleteConfirmTitle' => 'Konto löschen?',
			'settings.account.deleteConfirmMessage' => 'Dies löscht dein Konto und alle zugehörigen Daten dauerhaft. Dies kann nicht rückgängig gemacht werden.',
			'settings.account.deleteConfirmButton' => 'Löschen',
			'settings.account.deleteCancelButton' => 'Abbrechen',
			'settings.account.deleteOwnsTeams' => ({required Object teams}) => 'Du bist Eigentümer von ${teams}. Übertrage die Inhaberschaft an ein anderes Mitglied oder lösche das Team unter Einstellungen > Teams, bevor du dein Konto löschst.',
			'settings.account.deleteFailed' => 'Dein Konto konnte nicht gelöscht werden. Bitte versuche es erneut.',
			'settings.privacy.title' => 'Datenschutz',
			'settings.privacy.consentSectionTitle' => 'Einwilligung',
			'settings.privacy.consentStatusAccepted' => 'Du hast Analyse-Tracking akzeptiert.',
			'settings.privacy.consentStatusRejected' => 'Du hast Analyse-Tracking abgelehnt.',
			'settings.privacy.consentStatusNotSet' => 'Du hast noch keine Wahl getroffen.',
			'settings.privacy.changeConsentAccept' => 'Akzeptieren',
			'settings.privacy.changeConsentReject' => 'Ablehnen',
			'settings.privacy.consentChipAccepted' => 'Akzeptiert',
			'settings.privacy.consentChipRejected' => 'Abgelehnt',
			'settings.privacy.consentChipNotSet' => 'Nicht festgelegt',
			'settings.privacy.exportTitle' => 'Deine Daten exportieren',
			'settings.privacy.exportDescription' => 'Lade eine Kopie der mit deinem Konto verknüpften Daten im JSON-Format herunter.',
			'settings.privacy.exportButton' => 'Meine Daten exportieren',
			'settings.privacy.exportStepUpTitle' => 'Bestätige, dass du es bist',
			'settings.privacy.exportStepUpMessage' => 'Zu deiner Sicherheit bestätige bitte deine E-Mail-Adresse erneut, bevor wir deine Daten exportieren.',
			'settings.privacy.exportCodeLabel' => '6-stelliger Code',
			'settings.privacy.exportVerifyButton' => 'Bestätigen und exportieren',
			'settings.privacy.exportResultTitle' => 'Deine Daten',
			'settings.privacy.exportCopyButton' => 'Kopieren',
			'settings.paywall.title' => 'Abonnement',
			'settings.paywall.statusNone' => 'Kein Abonnement',
			'settings.paywall.statusActive' => 'Aktiv',
			'settings.paywall.statusTrialing' => 'Testphase',
			'settings.paywall.statusPastDue' => 'Zahlung fehlgeschlagen, der Zugang bleibt vorerst bestehen',
			'settings.paywall.statusExpired' => 'Zahlung fehlgeschlagen, der Zugang ist beendet',
			'settings.paywall.statusPaused' => 'Pausiert',
			'settings.paywall.statusCanceled' => 'Gekündigt',
			'settings.paywall.quantityValue' => ({required Object count}) => '${count} Einheiten',
			'settings.paywall.renewsOn' => ({required Object date}) => 'Verlängert sich am ${date}',
			'settings.paywall.cancelsOn' => ({required Object date}) => 'Endet am ${date}',
			'settings.paywall.graceEndsOn' => ({required Object date}) => 'Aktualisiere deine Zahlungsmethode vor dem ${date}',
			'settings.paywall.quantityLabel' => 'Einheiten',
			'settings.paywall.increaseLabel' => 'Eine Einheit mehr',
			'settings.paywall.decreaseLabel' => 'Eine Einheit weniger',
			'settings.paywall.subscribeButton' => 'Abonnieren',
			'settings.paywall.applyQuantityButton' => 'Einheiten ändern (anteilig)',
			'settings.paywall.manageButton' => 'Abrechnung verwalten',
			'settings.paywall.refreshButton' => 'Ich habe bezahlt, aktualisieren',
			'settings.paywall.failed' => 'Das hat nicht geklappt. Versuche es gleich noch einmal.',
			'settings.paywall.signedOut' => 'Melde dich an, um dein Abonnement zu verwalten.',
			'settings.teams.title' => 'Teams',
			'settings.teams.noTeams' => 'Du bist noch in keinem Team.',
			'settings.teams.activeChip' => 'Aktives Team',
			'settings.teams.switchButton' => 'Wechseln',
			'settings.teams.membersButton' => 'Mitglieder',
			'settings.teams.invitationsTitle' => 'Einladungen',
			'settings.teams.invitationRole' => ({required Object role}) => 'Eingeladen als ${role}',
			'settings.teams.acceptButton' => 'Annehmen',
			'settings.teams.createTitle' => 'Team erstellen',
			'settings.teams.nameLabel' => 'Teamname',
			'settings.teams.createButton' => 'Team erstellen',
			'settings.teams.failed' => 'Das hat nicht geklappt. Prüfe deine Verbindung und Berechtigungen und versuche es erneut.',
			'settings.teams.members.title' => 'Mitglieder',
			'settings.teams.members.noActiveTeam' => 'Erstelle oder wähle zuerst ein Team.',
			'settings.teams.members.roleOwner' => 'Inhaber',
			'settings.teams.members.roleAdmin' => 'Admin',
			'settings.teams.members.roleMember' => 'Mitglied',
			'settings.teams.members.inviteTitle' => 'Jemanden einladen',
			'settings.teams.members.emailLabel' => 'E-Mail-Adresse',
			'settings.teams.members.inviteButton' => 'Einladung senden',
			'settings.teams.members.pendingTitle' => 'Offene Einladungen',
			'settings.teams.members.pendingExpires' => ({required Object date}) => 'Läuft ab am ${date}',
			'settings.teams.members.revokeButton' => 'Zurückziehen',
			'settings.teams.members.leaveButton' => 'Team verlassen',
			'legal.title' => 'Rechtliches',
			'legal.impressum' => 'Impressum',
			'legal.datenschutz' => 'Datenschutzerklärung',
			'legal.agb' => 'AGB',
			'legal.barrierefreiheit' => 'Barrierefreiheit',
			'legal.licencesLink' => 'Open-Source-Lizenzen',
			'legal.document.templateNotice' => 'PLATZHALTERTEXT — vor Veröffentlichung durch anwaltlich geprüften Text ersetzen.',
			'legal.document.impressumIntro' => 'Angaben gemäß § 5 DDG:',
			'legal.document.datenschutzIntro' => 'Dies ist eine Platzhalter-Datenschutzerklärung. Ersetze sie durch eine DSGVO-Art.-13-konforme Erklärung, die beschreibt, welche Daten diese App tatsächlich erhebt und warum.',
			'legal.document.agbIntro' => 'Dies sind Platzhalter-Allgemeine-Geschäftsbedingungen.',
			'legal.document.barrierefreiheitIntro' => 'Dies ist eine Platzhalter-Erklärung zur Barrierefreiheit.',
			'legal.document.factCompanyName' => 'Unternehmen',
			'legal.document.factAddress' => 'Anschrift',
			'legal.document.factRegister' => 'Registereintrag',
			'legal.document.factVatId' => 'USt-IdNr.',
			'legal.document.factContactEmail' => 'Kontakt',
			'legal.document.factResponsiblePerson' => 'Verantwortlich für den Inhalt (§ 18 Abs. 2 MStV)',
			'legal.document.factSupervisoryAuthority' => 'Aufsichtsbehörde',
			'legal.licences.title' => 'Open-Source-Lizenzen',
			'legal.licences.copyButton' => 'Kopieren',
			'legal.licences.empty' => 'Es wurden keine Lizenzen von Drittanbietern gefunden.',
			_ => null,
		};
	}
}
