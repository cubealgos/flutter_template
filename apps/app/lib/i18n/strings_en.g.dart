///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	dynamic operator[](String key) => _meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations

	/// en: 'flutter_template'
	String get appTitle => 'flutter_template';

	late final Translations$common$en common = Translations$common$en.internal(_root);
	late final Translations$bootstrap$en bootstrap = Translations$bootstrap$en.internal(_root);
	late final Translations$consent$en consent = Translations$consent$en.internal(_root);
	late final Translations$signIn$en signIn = Translations$signIn$en.internal(_root);
	late final Translations$onboarding$en onboarding = Translations$onboarding$en.internal(_root);
	late final Translations$permissionPrePrompt$en permissionPrePrompt = Translations$permissionPrePrompt$en.internal(_root);
	late final Translations$home$en home = Translations$home$en.internal(_root);
	late final Translations$settings$en settings = Translations$settings$en.internal(_root);
	late final Translations$legal$en legal = Translations$legal$en.internal(_root);
}

// Path: common
class Translations$common$en {
	Translations$common$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Close'
	String get close => 'Close';

	/// en: 'Back'
	String get back => 'Back';

	/// en: 'Continue'
	String get continueLabel => 'Continue';

	/// en: 'Not now'
	String get notNow => 'Not now';

	/// en: 'Legal'
	String get legalLink => 'Legal';

	/// en: 'Terms & Conditions'
	String get agbLink => 'Terms & Conditions';

	/// en: 'Privacy Policy'
	String get datenschutzLink => 'Privacy Policy';

	/// en: 'or'
	String get orDivider => 'or';
}

// Path: bootstrap
class Translations$bootstrap$en {
	Translations$bootstrap$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Checking for updates…'
	String get checkingVersion => 'Checking for updates…';

	/// en: 'Update required'
	String get blockedTitle => 'Update required';

	/// en: 'This version of the app is no longer supported. Please update to continue.'
	String get blockedMessage => 'This version of the app is no longer supported. Please update to continue.';

	/// en: 'Update now'
	String get updateButton => 'Update now';
}

// Path: consent
class Translations$consent$en {
	Translations$consent$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Consent'
	String get eyebrowLabel => 'Consent';

	/// en: 'Before you continue'
	String get title => 'Before you continue';

	/// en: 'We'd like to use analytics to improve this app. You can change your choice at any time in Settings → Privacy.'
	String get message => 'We\'d like to use analytics to improve this app. You can change your choice at any time in Settings → Privacy.';

	/// en: 'Accept'
	String get accept => 'Accept';

	/// en: 'Reject'
	String get reject => 'Reject';

	/// en: 'Manage in Settings'
	String get settingsLink => 'Manage in Settings';
}

// Path: signIn
class Translations$signIn$en {
	Translations$signIn$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Sign in'
	String get title => 'Sign in';

	/// en: 'Email address'
	String get emailLabel => 'Email address';

	/// en: 'Send code'
	String get requestCodeButton => 'Send code';

	/// en: '6-digit code'
	String get codeLabel => '6-digit code';

	/// en: 'Enter the code we sent to $email'
	String codeHint({required Object email}) => 'Enter the code we sent to ${email}';

	/// en: 'Verify'
	String get verifyButton => 'Verify';

	/// en: 'Use a different email'
	String get changeEmailButton => 'Use a different email';

	/// en: 'Resend code'
	String get resendCodeButton => 'Resend code';

	/// en: 'Sign in with a passkey'
	String get passkeyButton => 'Sign in with a passkey';

	/// en: 'Sign in with Apple'
	String get appleButton => 'Sign in with Apple';

	/// en: 'Sign in with Google'
	String get googleButton => 'Sign in with Google';

	/// en: 'Continue as App Review demo account'
	String get reviewerButton => 'Continue as App Review demo account';

	/// en: 'Enter the App Review code from the store review notes'
	String get reviewCodeHint => 'Enter the App Review code from the store review notes';

	/// en: 'Review code'
	String get reviewCodeLabel => 'Review code';

	/// en: 'Sign in as reviewer'
	String get reviewerSubmitButton => 'Sign in as reviewer';

	/// en: 'Something went wrong. Please try again.'
	String get errorGeneric => 'Something went wrong. Please try again.';

	/// en: 'That code isn't right. Please try again.'
	String get errorInvalidCode => 'That code isn\'t right. Please try again.';

	/// en: 'Too many attempts. Please wait a moment and try again.'
	String get errorRateLimited => 'Too many attempts. Please wait a moment and try again.';
}

// Path: onboarding
class Translations$onboarding$en {
	Translations$onboarding$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Step ${current} of ${total}'
	String stepProgress({required Object current, required Object total}) => 'Step ${current} of ${total}';

	/// en: 'Next'
	String get nextButton => 'Next';

	/// en: 'Skip for now'
	String get skipForNow => 'Skip for now';

	/// en: 'Saved'
	String get savedHint => 'Saved';

	/// en: 'Profile'
	String get stepProfileTitle => 'Profile';

	/// en: 'Display name'
	String get stepProfileDisplayNameLabel => 'Display name';

	/// en: 'Add photo'
	String get stepProfileAddPhotoButton => 'Add photo';

	/// en: 'Preferences'
	String get stepPreferencesTitle => 'Preferences';

	/// en: 'How do you want to use ${appName}?'
	String stepPreferencesQuestion({required Object appName}) => 'How do you want to use ${appName}?';

	/// en: 'Personal use'
	String get stepPreferencesOptionPersonalTitle => 'Personal use';

	/// en: 'Just for you'
	String get stepPreferencesOptionPersonalHint => 'Just for you';

	/// en: 'Work / team'
	String get stepPreferencesOptionWorkTitle => 'Work / team';

	/// en: 'Shared with colleagues'
	String get stepPreferencesOptionWorkHint => 'Shared with colleagues';

	/// en: 'Just exploring'
	String get stepPreferencesOptionExploringTitle => 'Just exploring';

	/// en: 'Not sure yet'
	String get stepPreferencesOptionExploringHint => 'Not sure yet';

	/// en: 'Notifications'
	String get stepNotificationsTitle => 'Notifications';
}

// Path: permissionPrePrompt
class Translations$permissionPrePrompt$en {
	Translations$permissionPrePrompt$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Stay in the loop'
	String get pushTitle => 'Stay in the loop';

	/// en: 'Turning on notifications lets us tell you about things that matter to you. You can change this later in your device settings.'
	String get pushMessage => 'Turning on notifications lets us tell you about things that matter to you. You can change this later in your device settings.';

	/// en: 'Help us keep this app free'
	String get attTitle => 'Help us keep this app free';

	/// en: 'Allowing tracking helps us show you relevant content. You can change this later in your device settings.'
	String get attMessage => 'Allowing tracking helps us show you relevant content. You can change this later in your device settings.';

	/// en: 'Use your location'
	String get locationTitle => 'Use your location';

	/// en: 'Sharing your location lets us tailor the app to where you are. You can change this later in your device settings.'
	String get locationMessage => 'Sharing your location lets us tailor the app to where you are. You can change this later in your device settings.';
}

// Path: home
class Translations$home$en {
	Translations$home$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Home'
	String get title => 'Home';

	/// en: 'Nothing here yet — this is where your content will show up.'
	String get emptyStateMessage => 'Nothing here yet — this is where your content will show up.';

	/// en: 'Settings'
	String get settingsButton => 'Settings';

	/// en: 'Sign out'
	String get signOutButton => 'Sign out';

	/// en: 'Finish your setup'
	String get setupCardTitle => 'Finish your setup';

	/// en: '${completed} of ${total} done'
	String setupCardProgress({required Object completed, required Object total}) => '${completed} of ${total} done';

	/// en: 'Dismiss'
	String get setupCardDismiss => 'Dismiss';
}

// Path: settings
class Translations$settings$en {
	Translations$settings$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Settings'
	String get title => 'Settings';

	/// en: 'Legal'
	String get legalLink => 'Legal';

	/// en: 'Privacy'
	String get privacyLink => 'Privacy';

	/// en: 'Account'
	String get accountLink => 'Account';

	/// en: 'Teams'
	String get teamsLink => 'Teams';

	/// en: 'Subscription'
	String get paywallLink => 'Subscription';

	late final Translations$settings$account$en account = Translations$settings$account$en.internal(_root);
	late final Translations$settings$privacy$en privacy = Translations$settings$privacy$en.internal(_root);
	late final Translations$settings$paywall$en paywall = Translations$settings$paywall$en.internal(_root);
	late final Translations$settings$teams$en teams = Translations$settings$teams$en.internal(_root);
}

// Path: legal
class Translations$legal$en {
	Translations$legal$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Legal'
	String get title => 'Legal';

	/// en: 'Impressum'
	String get impressum => 'Impressum';

	/// en: 'Datenschutz (Privacy Policy)'
	String get datenschutz => 'Datenschutz (Privacy Policy)';

	/// en: 'AGB (Terms & Conditions)'
	String get agb => 'AGB (Terms & Conditions)';

	/// en: 'Barrierefreiheit (Accessibility)'
	String get barrierefreiheit => 'Barrierefreiheit (Accessibility)';

	/// en: 'Open-source licences'
	String get licencesLink => 'Open-source licences';

	late final Translations$legal$document$en document = Translations$legal$document$en.internal(_root);
	late final Translations$legal$licences$en licences = Translations$legal$licences$en.internal(_root);
}

// Path: settings.account
class Translations$settings$account$en {
	Translations$settings$account$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Account'
	String get title => 'Account';

	/// en: 'Linked accounts'
	String get linkedIdentitiesTitle => 'Linked accounts';

	/// en: 'No social accounts are linked.'
	String get noLinkedIdentities => 'No social accounts are linked.';

	/// en: 'Disconnect'
	String get disconnectButton => 'Disconnect';

	/// en: 'Danger zone'
	String get dangerZoneLabel => 'Danger zone';

	/// en: 'Delete account'
	String get deleteAccountButton => 'Delete account';

	/// en: 'Delete your account?'
	String get deleteConfirmTitle => 'Delete your account?';

	/// en: 'This permanently deletes your account and all associated data. This can't be undone.'
	String get deleteConfirmMessage => 'This permanently deletes your account and all associated data. This can\'t be undone.';

	/// en: 'Delete'
	String get deleteConfirmButton => 'Delete';

	/// en: 'Cancel'
	String get deleteCancelButton => 'Cancel';

	/// en: 'You own ${teams}. Transfer ownership to another member, or delete the team, under Settings > Teams before deleting your account.'
	String deleteOwnsTeams({required Object teams}) => 'You own ${teams}. Transfer ownership to another member, or delete the team, under Settings > Teams before deleting your account.';

	/// en: 'Your account could not be deleted. Please try again.'
	String get deleteFailed => 'Your account could not be deleted. Please try again.';
}

// Path: settings.privacy
class Translations$settings$privacy$en {
	Translations$settings$privacy$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Privacy'
	String get title => 'Privacy';

	/// en: 'Consent'
	String get consentSectionTitle => 'Consent';

	/// en: 'You've accepted analytics.'
	String get consentStatusAccepted => 'You\'ve accepted analytics.';

	/// en: 'You've rejected analytics.'
	String get consentStatusRejected => 'You\'ve rejected analytics.';

	/// en: 'You haven't made a choice yet.'
	String get consentStatusNotSet => 'You haven\'t made a choice yet.';

	/// en: 'Accept'
	String get changeConsentAccept => 'Accept';

	/// en: 'Reject'
	String get changeConsentReject => 'Reject';

	/// en: 'Accepted'
	String get consentChipAccepted => 'Accepted';

	/// en: 'Rejected'
	String get consentChipRejected => 'Rejected';

	/// en: 'Not set'
	String get consentChipNotSet => 'Not set';

	/// en: 'Export your data'
	String get exportTitle => 'Export your data';

	/// en: 'Download a copy of the data linked to your account, in JSON format.'
	String get exportDescription => 'Download a copy of the data linked to your account, in JSON format.';

	/// en: 'Export my data'
	String get exportButton => 'Export my data';

	/// en: 'Confirm it's you'
	String get exportStepUpTitle => 'Confirm it\'s you';

	/// en: 'For your security, please re-verify your email before we export your data.'
	String get exportStepUpMessage => 'For your security, please re-verify your email before we export your data.';

	/// en: '6-digit code'
	String get exportCodeLabel => '6-digit code';

	/// en: 'Verify and export'
	String get exportVerifyButton => 'Verify and export';

	/// en: 'Your data'
	String get exportResultTitle => 'Your data';

	/// en: 'Copy'
	String get exportCopyButton => 'Copy';
}

// Path: settings.paywall
class Translations$settings$paywall$en {
	Translations$settings$paywall$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Subscription'
	String get title => 'Subscription';

	/// en: 'No subscription'
	String get statusNone => 'No subscription';

	/// en: 'Active'
	String get statusActive => 'Active';

	/// en: 'In trial'
	String get statusTrialing => 'In trial';

	/// en: 'Payment failed, access continues for now'
	String get statusPastDue => 'Payment failed, access continues for now';

	/// en: 'Payment failed, access has ended'
	String get statusExpired => 'Payment failed, access has ended';

	/// en: 'Paused'
	String get statusPaused => 'Paused';

	/// en: 'Canceled'
	String get statusCanceled => 'Canceled';

	/// en: '${count} units'
	String quantityValue({required Object count}) => '${count} units';

	/// en: 'Renews on ${date}'
	String renewsOn({required Object date}) => 'Renews on ${date}';

	/// en: 'Ends on ${date}'
	String cancelsOn({required Object date}) => 'Ends on ${date}';

	/// en: 'Update your payment method before ${date}'
	String graceEndsOn({required Object date}) => 'Update your payment method before ${date}';

	/// en: 'Units'
	String get quantityLabel => 'Units';

	/// en: 'One more unit'
	String get increaseLabel => 'One more unit';

	/// en: 'One unit fewer'
	String get decreaseLabel => 'One unit fewer';

	/// en: 'Subscribe'
	String get subscribeButton => 'Subscribe';

	/// en: 'Change units (prorated)'
	String get applyQuantityButton => 'Change units (prorated)';

	/// en: 'Manage billing'
	String get manageButton => 'Manage billing';

	/// en: 'I have paid, refresh'
	String get refreshButton => 'I have paid, refresh';

	/// en: 'That didn't work. Try again in a moment.'
	String get failed => 'That didn\'t work. Try again in a moment.';

	/// en: 'Sign in to manage your subscription.'
	String get signedOut => 'Sign in to manage your subscription.';
}

// Path: settings.teams
class Translations$settings$teams$en {
	Translations$settings$teams$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Teams'
	String get title => 'Teams';

	/// en: 'You aren't in a team yet.'
	String get noTeams => 'You aren\'t in a team yet.';

	/// en: 'Active team'
	String get activeChip => 'Active team';

	/// en: 'Switch'
	String get switchButton => 'Switch';

	/// en: 'Members'
	String get membersButton => 'Members';

	/// en: 'Invitations'
	String get invitationsTitle => 'Invitations';

	/// en: 'Invited as ${role}'
	String invitationRole({required Object role}) => 'Invited as ${role}';

	/// en: 'Accept'
	String get acceptButton => 'Accept';

	/// en: 'Create a team'
	String get createTitle => 'Create a team';

	/// en: 'Team name'
	String get nameLabel => 'Team name';

	/// en: 'Create team'
	String get createButton => 'Create team';

	/// en: 'That didn't work. Check your connection and permissions, then try again.'
	String get failed => 'That didn\'t work. Check your connection and permissions, then try again.';

	late final Translations$settings$teams$members$en members = Translations$settings$teams$members$en.internal(_root);
}

// Path: legal.document
class Translations$legal$document$en {
	Translations$legal$document$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'TEMPLATE TEXT — replace with your own lawyer-reviewed text before shipping.'
	String get templateNotice => 'TEMPLATE TEXT — replace with your own lawyer-reviewed text before shipping.';

	/// en: 'Information required under § 5 DDG:'
	String get impressumIntro => 'Information required under § 5 DDG:';

	/// en: 'This is a placeholder privacy policy. Replace it with a GDPR Art. 13-compliant policy describing what data this app actually collects and why.'
	String get datenschutzIntro => 'This is a placeholder privacy policy. Replace it with a GDPR Art. 13-compliant policy describing what data this app actually collects and why.';

	/// en: 'This is a placeholder terms & conditions document.'
	String get agbIntro => 'This is a placeholder terms & conditions document.';

	/// en: 'This is a placeholder accessibility statement.'
	String get barrierefreiheitIntro => 'This is a placeholder accessibility statement.';

	/// en: 'Company'
	String get factCompanyName => 'Company';

	/// en: 'Address'
	String get factAddress => 'Address';

	/// en: 'Register entry'
	String get factRegister => 'Register entry';

	/// en: 'VAT ID'
	String get factVatId => 'VAT ID';

	/// en: 'Contact'
	String get factContactEmail => 'Contact';

	/// en: 'Responsible for content (§ 18 (2) MStV)'
	String get factResponsiblePerson => 'Responsible for content (§ 18 (2) MStV)';

	/// en: 'Supervisory authority'
	String get factSupervisoryAuthority => 'Supervisory authority';
}

// Path: legal.licences
class Translations$legal$licences$en {
	Translations$legal$licences$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Open-source licences'
	String get title => 'Open-source licences';

	/// en: 'Copy'
	String get copyButton => 'Copy';

	/// en: 'No third-party licences were found.'
	String get empty => 'No third-party licences were found.';
}

// Path: settings.teams.members
class Translations$settings$teams$members$en {
	Translations$settings$teams$members$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Members'
	String get title => 'Members';

	/// en: 'Create or pick a team first.'
	String get noActiveTeam => 'Create or pick a team first.';

	/// en: 'Owner'
	String get roleOwner => 'Owner';

	/// en: 'Admin'
	String get roleAdmin => 'Admin';

	/// en: 'Member'
	String get roleMember => 'Member';

	/// en: 'Invite someone'
	String get inviteTitle => 'Invite someone';

	/// en: 'Email address'
	String get emailLabel => 'Email address';

	/// en: 'Send invitation'
	String get inviteButton => 'Send invitation';

	/// en: 'Pending invitations'
	String get pendingTitle => 'Pending invitations';

	/// en: 'Expires ${date}'
	String pendingExpires({required Object date}) => 'Expires ${date}';

	/// en: 'Revoke'
	String get revokeButton => 'Revoke';

	/// en: 'Leave team'
	String get leaveButton => 'Leave team';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appTitle' => 'flutter_template',
			'common.cancel' => 'Cancel',
			'common.close' => 'Close',
			'common.back' => 'Back',
			'common.continueLabel' => 'Continue',
			'common.notNow' => 'Not now',
			'common.legalLink' => 'Legal',
			'common.agbLink' => 'Terms & Conditions',
			'common.datenschutzLink' => 'Privacy Policy',
			'common.orDivider' => 'or',
			'bootstrap.checkingVersion' => 'Checking for updates…',
			'bootstrap.blockedTitle' => 'Update required',
			'bootstrap.blockedMessage' => 'This version of the app is no longer supported. Please update to continue.',
			'bootstrap.updateButton' => 'Update now',
			'consent.eyebrowLabel' => 'Consent',
			'consent.title' => 'Before you continue',
			'consent.message' => 'We\'d like to use analytics to improve this app. You can change your choice at any time in Settings → Privacy.',
			'consent.accept' => 'Accept',
			'consent.reject' => 'Reject',
			'consent.settingsLink' => 'Manage in Settings',
			'signIn.title' => 'Sign in',
			'signIn.emailLabel' => 'Email address',
			'signIn.requestCodeButton' => 'Send code',
			'signIn.codeLabel' => '6-digit code',
			'signIn.codeHint' => ({required Object email}) => 'Enter the code we sent to ${email}',
			'signIn.verifyButton' => 'Verify',
			'signIn.changeEmailButton' => 'Use a different email',
			'signIn.resendCodeButton' => 'Resend code',
			'signIn.passkeyButton' => 'Sign in with a passkey',
			'signIn.appleButton' => 'Sign in with Apple',
			'signIn.googleButton' => 'Sign in with Google',
			'signIn.reviewerButton' => 'Continue as App Review demo account',
			'signIn.reviewCodeHint' => 'Enter the App Review code from the store review notes',
			'signIn.reviewCodeLabel' => 'Review code',
			'signIn.reviewerSubmitButton' => 'Sign in as reviewer',
			'signIn.errorGeneric' => 'Something went wrong. Please try again.',
			'signIn.errorInvalidCode' => 'That code isn\'t right. Please try again.',
			'signIn.errorRateLimited' => 'Too many attempts. Please wait a moment and try again.',
			'onboarding.stepProgress' => ({required Object current, required Object total}) => 'Step ${current} of ${total}',
			'onboarding.nextButton' => 'Next',
			'onboarding.skipForNow' => 'Skip for now',
			'onboarding.savedHint' => 'Saved',
			'onboarding.stepProfileTitle' => 'Profile',
			'onboarding.stepProfileDisplayNameLabel' => 'Display name',
			'onboarding.stepProfileAddPhotoButton' => 'Add photo',
			'onboarding.stepPreferencesTitle' => 'Preferences',
			'onboarding.stepPreferencesQuestion' => ({required Object appName}) => 'How do you want to use ${appName}?',
			'onboarding.stepPreferencesOptionPersonalTitle' => 'Personal use',
			'onboarding.stepPreferencesOptionPersonalHint' => 'Just for you',
			'onboarding.stepPreferencesOptionWorkTitle' => 'Work / team',
			'onboarding.stepPreferencesOptionWorkHint' => 'Shared with colleagues',
			'onboarding.stepPreferencesOptionExploringTitle' => 'Just exploring',
			'onboarding.stepPreferencesOptionExploringHint' => 'Not sure yet',
			'onboarding.stepNotificationsTitle' => 'Notifications',
			'permissionPrePrompt.pushTitle' => 'Stay in the loop',
			'permissionPrePrompt.pushMessage' => 'Turning on notifications lets us tell you about things that matter to you. You can change this later in your device settings.',
			'permissionPrePrompt.attTitle' => 'Help us keep this app free',
			'permissionPrePrompt.attMessage' => 'Allowing tracking helps us show you relevant content. You can change this later in your device settings.',
			'permissionPrePrompt.locationTitle' => 'Use your location',
			'permissionPrePrompt.locationMessage' => 'Sharing your location lets us tailor the app to where you are. You can change this later in your device settings.',
			'home.title' => 'Home',
			'home.emptyStateMessage' => 'Nothing here yet — this is where your content will show up.',
			'home.settingsButton' => 'Settings',
			'home.signOutButton' => 'Sign out',
			'home.setupCardTitle' => 'Finish your setup',
			'home.setupCardProgress' => ({required Object completed, required Object total}) => '${completed} of ${total} done',
			'home.setupCardDismiss' => 'Dismiss',
			'settings.title' => 'Settings',
			'settings.legalLink' => 'Legal',
			'settings.privacyLink' => 'Privacy',
			'settings.accountLink' => 'Account',
			'settings.teamsLink' => 'Teams',
			'settings.paywallLink' => 'Subscription',
			'settings.account.title' => 'Account',
			'settings.account.linkedIdentitiesTitle' => 'Linked accounts',
			'settings.account.noLinkedIdentities' => 'No social accounts are linked.',
			'settings.account.disconnectButton' => 'Disconnect',
			'settings.account.dangerZoneLabel' => 'Danger zone',
			'settings.account.deleteAccountButton' => 'Delete account',
			'settings.account.deleteConfirmTitle' => 'Delete your account?',
			'settings.account.deleteConfirmMessage' => 'This permanently deletes your account and all associated data. This can\'t be undone.',
			'settings.account.deleteConfirmButton' => 'Delete',
			'settings.account.deleteCancelButton' => 'Cancel',
			'settings.account.deleteOwnsTeams' => ({required Object teams}) => 'You own ${teams}. Transfer ownership to another member, or delete the team, under Settings > Teams before deleting your account.',
			'settings.account.deleteFailed' => 'Your account could not be deleted. Please try again.',
			'settings.privacy.title' => 'Privacy',
			'settings.privacy.consentSectionTitle' => 'Consent',
			'settings.privacy.consentStatusAccepted' => 'You\'ve accepted analytics.',
			'settings.privacy.consentStatusRejected' => 'You\'ve rejected analytics.',
			'settings.privacy.consentStatusNotSet' => 'You haven\'t made a choice yet.',
			'settings.privacy.changeConsentAccept' => 'Accept',
			'settings.privacy.changeConsentReject' => 'Reject',
			'settings.privacy.consentChipAccepted' => 'Accepted',
			'settings.privacy.consentChipRejected' => 'Rejected',
			'settings.privacy.consentChipNotSet' => 'Not set',
			'settings.privacy.exportTitle' => 'Export your data',
			'settings.privacy.exportDescription' => 'Download a copy of the data linked to your account, in JSON format.',
			'settings.privacy.exportButton' => 'Export my data',
			'settings.privacy.exportStepUpTitle' => 'Confirm it\'s you',
			'settings.privacy.exportStepUpMessage' => 'For your security, please re-verify your email before we export your data.',
			'settings.privacy.exportCodeLabel' => '6-digit code',
			'settings.privacy.exportVerifyButton' => 'Verify and export',
			'settings.privacy.exportResultTitle' => 'Your data',
			'settings.privacy.exportCopyButton' => 'Copy',
			'settings.paywall.title' => 'Subscription',
			'settings.paywall.statusNone' => 'No subscription',
			'settings.paywall.statusActive' => 'Active',
			'settings.paywall.statusTrialing' => 'In trial',
			'settings.paywall.statusPastDue' => 'Payment failed, access continues for now',
			'settings.paywall.statusExpired' => 'Payment failed, access has ended',
			'settings.paywall.statusPaused' => 'Paused',
			'settings.paywall.statusCanceled' => 'Canceled',
			'settings.paywall.quantityValue' => ({required Object count}) => '${count} units',
			'settings.paywall.renewsOn' => ({required Object date}) => 'Renews on ${date}',
			'settings.paywall.cancelsOn' => ({required Object date}) => 'Ends on ${date}',
			'settings.paywall.graceEndsOn' => ({required Object date}) => 'Update your payment method before ${date}',
			'settings.paywall.quantityLabel' => 'Units',
			'settings.paywall.increaseLabel' => 'One more unit',
			'settings.paywall.decreaseLabel' => 'One unit fewer',
			'settings.paywall.subscribeButton' => 'Subscribe',
			'settings.paywall.applyQuantityButton' => 'Change units (prorated)',
			'settings.paywall.manageButton' => 'Manage billing',
			'settings.paywall.refreshButton' => 'I have paid, refresh',
			'settings.paywall.failed' => 'That didn\'t work. Try again in a moment.',
			'settings.paywall.signedOut' => 'Sign in to manage your subscription.',
			'settings.teams.title' => 'Teams',
			'settings.teams.noTeams' => 'You aren\'t in a team yet.',
			'settings.teams.activeChip' => 'Active team',
			'settings.teams.switchButton' => 'Switch',
			'settings.teams.membersButton' => 'Members',
			'settings.teams.invitationsTitle' => 'Invitations',
			'settings.teams.invitationRole' => ({required Object role}) => 'Invited as ${role}',
			'settings.teams.acceptButton' => 'Accept',
			'settings.teams.createTitle' => 'Create a team',
			'settings.teams.nameLabel' => 'Team name',
			'settings.teams.createButton' => 'Create team',
			'settings.teams.failed' => 'That didn\'t work. Check your connection and permissions, then try again.',
			'settings.teams.members.title' => 'Members',
			'settings.teams.members.noActiveTeam' => 'Create or pick a team first.',
			'settings.teams.members.roleOwner' => 'Owner',
			'settings.teams.members.roleAdmin' => 'Admin',
			'settings.teams.members.roleMember' => 'Member',
			'settings.teams.members.inviteTitle' => 'Invite someone',
			'settings.teams.members.emailLabel' => 'Email address',
			'settings.teams.members.inviteButton' => 'Send invitation',
			'settings.teams.members.pendingTitle' => 'Pending invitations',
			'settings.teams.members.pendingExpires' => ({required Object date}) => 'Expires ${date}',
			'settings.teams.members.revokeButton' => 'Revoke',
			'settings.teams.members.leaveButton' => 'Leave team',
			'legal.title' => 'Legal',
			'legal.impressum' => 'Impressum',
			'legal.datenschutz' => 'Datenschutz (Privacy Policy)',
			'legal.agb' => 'AGB (Terms & Conditions)',
			'legal.barrierefreiheit' => 'Barrierefreiheit (Accessibility)',
			'legal.licencesLink' => 'Open-source licences',
			'legal.document.templateNotice' => 'TEMPLATE TEXT — replace with your own lawyer-reviewed text before shipping.',
			'legal.document.impressumIntro' => 'Information required under § 5 DDG:',
			'legal.document.datenschutzIntro' => 'This is a placeholder privacy policy. Replace it with a GDPR Art. 13-compliant policy describing what data this app actually collects and why.',
			'legal.document.agbIntro' => 'This is a placeholder terms & conditions document.',
			'legal.document.barrierefreiheitIntro' => 'This is a placeholder accessibility statement.',
			'legal.document.factCompanyName' => 'Company',
			'legal.document.factAddress' => 'Address',
			'legal.document.factRegister' => 'Register entry',
			'legal.document.factVatId' => 'VAT ID',
			'legal.document.factContactEmail' => 'Contact',
			'legal.document.factResponsiblePerson' => 'Responsible for content (§ 18 (2) MStV)',
			'legal.document.factSupervisoryAuthority' => 'Supervisory authority',
			'legal.licences.title' => 'Open-source licences',
			'legal.licences.copyButton' => 'Copy',
			'legal.licences.empty' => 'No third-party licences were found.',
			_ => null,
		};
	}
}
