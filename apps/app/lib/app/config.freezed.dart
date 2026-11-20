// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppConfig {

/// Shows the consent sheet (Accept/Reject, no pre-ticking) on first
/// launch — see §25 TDDDG / Planet49 / LG München I.
 bool get consentSheet;/// Offers a passkey option on the sign-in screen.
 bool get passkeys;/// Offers "Sign in with Apple" on the sign-in screen.
 bool get socialLoginApple;/// Offers "Sign in with Google" on the sign-in screen. Requires
/// [socialLoginApple] — see this factory's `@Assert`.
 bool get socialLoginGoogle;/// Shows the subscription screen (web billing with a merchant of record;
/// a mobile clone selling through the stores replaces it).
 bool get paywall;/// Shows the Barrierefreiheit (accessibility statement) legal page.
 bool get accessibilityStatement;/// The legal entity's registered company name, e.g. for the Impressum.
 String get legalCompanyName;/// The legal entity's registered address.
 String get legalAddress;/// The commercial register entry (court and register number).
 String get legalRegister;/// The legal entity's VAT identification number.
 String get legalVatId;/// The contact email shown on legal pages.
 String get legalContactEmail;/// The natural person responsible for content per § 18 (2) MStV.
 String get legalResponsiblePerson;/// The supervisory authority shown on the Datenschutz page.
 String get legalSupervisoryAuthority;/// The running app's own version, compared against the backend's
/// minimum supported version at bootstrap (`VersionPolicy.check`) —
/// sourced from the `--dart-define=APP_VERSION=…` build argument in
/// `ServiceModule.appConfig` (see `apps/app/README.md`), not hand-set
/// here.
 String get appVersion;/// Shows the sign-in screen's "continue as reviewer" shortcut for App
/// Store/Play Store review (Apple guideline 2.1) — see
/// `SignInController.submitReviewCode`. Tapping it asks for a shared
/// review code (never an email or password: this template has no
/// password sign-in at all — see `AuthService.signInWithReviewCode`'s
/// dartdoc), which the reviewer types from the store's own review
/// notes. `false` (the default) hides the shortcut entirely — a
/// production build with `REVIEW_DEMO_ENABLED` unset ships no review
/// code UI at all. Sourced from `--dart-define=REVIEW_DEMO_ENABLED=…`,
/// never hard-coded — see `apps/app/README.md`'s "App Review demo
/// access" section for the full design.
 bool get reviewDemoEnabled;
/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigCopyWith<AppConfig> get copyWith => _$AppConfigCopyWithImpl<AppConfig>(this as AppConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfig&&(identical(other.consentSheet, consentSheet) || other.consentSheet == consentSheet)&&(identical(other.passkeys, passkeys) || other.passkeys == passkeys)&&(identical(other.socialLoginApple, socialLoginApple) || other.socialLoginApple == socialLoginApple)&&(identical(other.socialLoginGoogle, socialLoginGoogle) || other.socialLoginGoogle == socialLoginGoogle)&&(identical(other.paywall, paywall) || other.paywall == paywall)&&(identical(other.accessibilityStatement, accessibilityStatement) || other.accessibilityStatement == accessibilityStatement)&&(identical(other.legalCompanyName, legalCompanyName) || other.legalCompanyName == legalCompanyName)&&(identical(other.legalAddress, legalAddress) || other.legalAddress == legalAddress)&&(identical(other.legalRegister, legalRegister) || other.legalRegister == legalRegister)&&(identical(other.legalVatId, legalVatId) || other.legalVatId == legalVatId)&&(identical(other.legalContactEmail, legalContactEmail) || other.legalContactEmail == legalContactEmail)&&(identical(other.legalResponsiblePerson, legalResponsiblePerson) || other.legalResponsiblePerson == legalResponsiblePerson)&&(identical(other.legalSupervisoryAuthority, legalSupervisoryAuthority) || other.legalSupervisoryAuthority == legalSupervisoryAuthority)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.reviewDemoEnabled, reviewDemoEnabled) || other.reviewDemoEnabled == reviewDemoEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,consentSheet,passkeys,socialLoginApple,socialLoginGoogle,paywall,accessibilityStatement,legalCompanyName,legalAddress,legalRegister,legalVatId,legalContactEmail,legalResponsiblePerson,legalSupervisoryAuthority,appVersion,reviewDemoEnabled);

@override
String toString() {
  return 'AppConfig(consentSheet: $consentSheet, passkeys: $passkeys, socialLoginApple: $socialLoginApple, socialLoginGoogle: $socialLoginGoogle, paywall: $paywall, accessibilityStatement: $accessibilityStatement, legalCompanyName: $legalCompanyName, legalAddress: $legalAddress, legalRegister: $legalRegister, legalVatId: $legalVatId, legalContactEmail: $legalContactEmail, legalResponsiblePerson: $legalResponsiblePerson, legalSupervisoryAuthority: $legalSupervisoryAuthority, appVersion: $appVersion, reviewDemoEnabled: $reviewDemoEnabled)';
}


}

/// @nodoc
abstract mixin class $AppConfigCopyWith<$Res>  {
  factory $AppConfigCopyWith(AppConfig value, $Res Function(AppConfig) _then) = _$AppConfigCopyWithImpl;
@useResult
$Res call({
 bool consentSheet, bool passkeys, bool socialLoginApple, bool socialLoginGoogle, bool paywall, bool accessibilityStatement, String legalCompanyName, String legalAddress, String legalRegister, String legalVatId, String legalContactEmail, String legalResponsiblePerson, String legalSupervisoryAuthority, String appVersion, bool reviewDemoEnabled
});




}
/// @nodoc
class _$AppConfigCopyWithImpl<$Res>
    implements $AppConfigCopyWith<$Res> {
  _$AppConfigCopyWithImpl(this._self, this._then);

  final AppConfig _self;
  final $Res Function(AppConfig) _then;

/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? consentSheet = null,Object? passkeys = null,Object? socialLoginApple = null,Object? socialLoginGoogle = null,Object? paywall = null,Object? accessibilityStatement = null,Object? legalCompanyName = null,Object? legalAddress = null,Object? legalRegister = null,Object? legalVatId = null,Object? legalContactEmail = null,Object? legalResponsiblePerson = null,Object? legalSupervisoryAuthority = null,Object? appVersion = null,Object? reviewDemoEnabled = null,}) {
  return _then(_self.copyWith(
consentSheet: null == consentSheet ? _self.consentSheet : consentSheet // ignore: cast_nullable_to_non_nullable
as bool,passkeys: null == passkeys ? _self.passkeys : passkeys // ignore: cast_nullable_to_non_nullable
as bool,socialLoginApple: null == socialLoginApple ? _self.socialLoginApple : socialLoginApple // ignore: cast_nullable_to_non_nullable
as bool,socialLoginGoogle: null == socialLoginGoogle ? _self.socialLoginGoogle : socialLoginGoogle // ignore: cast_nullable_to_non_nullable
as bool,paywall: null == paywall ? _self.paywall : paywall // ignore: cast_nullable_to_non_nullable
as bool,accessibilityStatement: null == accessibilityStatement ? _self.accessibilityStatement : accessibilityStatement // ignore: cast_nullable_to_non_nullable
as bool,legalCompanyName: null == legalCompanyName ? _self.legalCompanyName : legalCompanyName // ignore: cast_nullable_to_non_nullable
as String,legalAddress: null == legalAddress ? _self.legalAddress : legalAddress // ignore: cast_nullable_to_non_nullable
as String,legalRegister: null == legalRegister ? _self.legalRegister : legalRegister // ignore: cast_nullable_to_non_nullable
as String,legalVatId: null == legalVatId ? _self.legalVatId : legalVatId // ignore: cast_nullable_to_non_nullable
as String,legalContactEmail: null == legalContactEmail ? _self.legalContactEmail : legalContactEmail // ignore: cast_nullable_to_non_nullable
as String,legalResponsiblePerson: null == legalResponsiblePerson ? _self.legalResponsiblePerson : legalResponsiblePerson // ignore: cast_nullable_to_non_nullable
as String,legalSupervisoryAuthority: null == legalSupervisoryAuthority ? _self.legalSupervisoryAuthority : legalSupervisoryAuthority // ignore: cast_nullable_to_non_nullable
as String,appVersion: null == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String,reviewDemoEnabled: null == reviewDemoEnabled ? _self.reviewDemoEnabled : reviewDemoEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AppConfig].
extension AppConfigPatterns on AppConfig {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppConfig() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppConfig value)  $default,){
final _that = this;
switch (_that) {
case _AppConfig():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppConfig value)?  $default,){
final _that = this;
switch (_that) {
case _AppConfig() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool consentSheet,  bool passkeys,  bool socialLoginApple,  bool socialLoginGoogle,  bool paywall,  bool accessibilityStatement,  String legalCompanyName,  String legalAddress,  String legalRegister,  String legalVatId,  String legalContactEmail,  String legalResponsiblePerson,  String legalSupervisoryAuthority,  String appVersion,  bool reviewDemoEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppConfig() when $default != null:
return $default(_that.consentSheet,_that.passkeys,_that.socialLoginApple,_that.socialLoginGoogle,_that.paywall,_that.accessibilityStatement,_that.legalCompanyName,_that.legalAddress,_that.legalRegister,_that.legalVatId,_that.legalContactEmail,_that.legalResponsiblePerson,_that.legalSupervisoryAuthority,_that.appVersion,_that.reviewDemoEnabled);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool consentSheet,  bool passkeys,  bool socialLoginApple,  bool socialLoginGoogle,  bool paywall,  bool accessibilityStatement,  String legalCompanyName,  String legalAddress,  String legalRegister,  String legalVatId,  String legalContactEmail,  String legalResponsiblePerson,  String legalSupervisoryAuthority,  String appVersion,  bool reviewDemoEnabled)  $default,) {final _that = this;
switch (_that) {
case _AppConfig():
return $default(_that.consentSheet,_that.passkeys,_that.socialLoginApple,_that.socialLoginGoogle,_that.paywall,_that.accessibilityStatement,_that.legalCompanyName,_that.legalAddress,_that.legalRegister,_that.legalVatId,_that.legalContactEmail,_that.legalResponsiblePerson,_that.legalSupervisoryAuthority,_that.appVersion,_that.reviewDemoEnabled);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool consentSheet,  bool passkeys,  bool socialLoginApple,  bool socialLoginGoogle,  bool paywall,  bool accessibilityStatement,  String legalCompanyName,  String legalAddress,  String legalRegister,  String legalVatId,  String legalContactEmail,  String legalResponsiblePerson,  String legalSupervisoryAuthority,  String appVersion,  bool reviewDemoEnabled)?  $default,) {final _that = this;
switch (_that) {
case _AppConfig() when $default != null:
return $default(_that.consentSheet,_that.passkeys,_that.socialLoginApple,_that.socialLoginGoogle,_that.paywall,_that.accessibilityStatement,_that.legalCompanyName,_that.legalAddress,_that.legalRegister,_that.legalVatId,_that.legalContactEmail,_that.legalResponsiblePerson,_that.legalSupervisoryAuthority,_that.appVersion,_that.reviewDemoEnabled);case _:
  return null;

}
}

}

/// @nodoc


class _AppConfig implements AppConfig {
  const _AppConfig({this.consentSheet = false, this.passkeys = false, this.socialLoginApple = false, this.socialLoginGoogle = false, this.paywall = false, this.accessibilityStatement = false, this.legalCompanyName = LegalFacts.companyName, this.legalAddress = LegalFacts.address, this.legalRegister = LegalFacts.register, this.legalVatId = LegalFacts.vatId, this.legalContactEmail = LegalFacts.contactEmail, this.legalResponsiblePerson = LegalFacts.responsiblePerson, this.legalSupervisoryAuthority = LegalFacts.supervisoryAuthority, this.appVersion = '1.0.0', this.reviewDemoEnabled = false}): assert(socialLoginApple || !socialLoginGoogle, 'Enabling Google social login requires Apple social login too (App Store guideline 4.8).');
  

/// Shows the consent sheet (Accept/Reject, no pre-ticking) on first
/// launch — see §25 TDDDG / Planet49 / LG München I.
@override@JsonKey() final  bool consentSheet;
/// Offers a passkey option on the sign-in screen.
@override@JsonKey() final  bool passkeys;
/// Offers "Sign in with Apple" on the sign-in screen.
@override@JsonKey() final  bool socialLoginApple;
/// Offers "Sign in with Google" on the sign-in screen. Requires
/// [socialLoginApple] — see this factory's `@Assert`.
@override@JsonKey() final  bool socialLoginGoogle;
/// Shows the subscription screen (web billing with a merchant of record;
/// a mobile clone selling through the stores replaces it).
@override@JsonKey() final  bool paywall;
/// Shows the Barrierefreiheit (accessibility statement) legal page.
@override@JsonKey() final  bool accessibilityStatement;
/// The legal entity's registered company name, e.g. for the Impressum.
@override@JsonKey() final  String legalCompanyName;
/// The legal entity's registered address.
@override@JsonKey() final  String legalAddress;
/// The commercial register entry (court and register number).
@override@JsonKey() final  String legalRegister;
/// The legal entity's VAT identification number.
@override@JsonKey() final  String legalVatId;
/// The contact email shown on legal pages.
@override@JsonKey() final  String legalContactEmail;
/// The natural person responsible for content per § 18 (2) MStV.
@override@JsonKey() final  String legalResponsiblePerson;
/// The supervisory authority shown on the Datenschutz page.
@override@JsonKey() final  String legalSupervisoryAuthority;
/// The running app's own version, compared against the backend's
/// minimum supported version at bootstrap (`VersionPolicy.check`) —
/// sourced from the `--dart-define=APP_VERSION=…` build argument in
/// `ServiceModule.appConfig` (see `apps/app/README.md`), not hand-set
/// here.
@override@JsonKey() final  String appVersion;
/// Shows the sign-in screen's "continue as reviewer" shortcut for App
/// Store/Play Store review (Apple guideline 2.1) — see
/// `SignInController.submitReviewCode`. Tapping it asks for a shared
/// review code (never an email or password: this template has no
/// password sign-in at all — see `AuthService.signInWithReviewCode`'s
/// dartdoc), which the reviewer types from the store's own review
/// notes. `false` (the default) hides the shortcut entirely — a
/// production build with `REVIEW_DEMO_ENABLED` unset ships no review
/// code UI at all. Sourced from `--dart-define=REVIEW_DEMO_ENABLED=…`,
/// never hard-coded — see `apps/app/README.md`'s "App Review demo
/// access" section for the full design.
@override@JsonKey() final  bool reviewDemoEnabled;

/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppConfigCopyWith<_AppConfig> get copyWith => __$AppConfigCopyWithImpl<_AppConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppConfig&&(identical(other.consentSheet, consentSheet) || other.consentSheet == consentSheet)&&(identical(other.passkeys, passkeys) || other.passkeys == passkeys)&&(identical(other.socialLoginApple, socialLoginApple) || other.socialLoginApple == socialLoginApple)&&(identical(other.socialLoginGoogle, socialLoginGoogle) || other.socialLoginGoogle == socialLoginGoogle)&&(identical(other.paywall, paywall) || other.paywall == paywall)&&(identical(other.accessibilityStatement, accessibilityStatement) || other.accessibilityStatement == accessibilityStatement)&&(identical(other.legalCompanyName, legalCompanyName) || other.legalCompanyName == legalCompanyName)&&(identical(other.legalAddress, legalAddress) || other.legalAddress == legalAddress)&&(identical(other.legalRegister, legalRegister) || other.legalRegister == legalRegister)&&(identical(other.legalVatId, legalVatId) || other.legalVatId == legalVatId)&&(identical(other.legalContactEmail, legalContactEmail) || other.legalContactEmail == legalContactEmail)&&(identical(other.legalResponsiblePerson, legalResponsiblePerson) || other.legalResponsiblePerson == legalResponsiblePerson)&&(identical(other.legalSupervisoryAuthority, legalSupervisoryAuthority) || other.legalSupervisoryAuthority == legalSupervisoryAuthority)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.reviewDemoEnabled, reviewDemoEnabled) || other.reviewDemoEnabled == reviewDemoEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,consentSheet,passkeys,socialLoginApple,socialLoginGoogle,paywall,accessibilityStatement,legalCompanyName,legalAddress,legalRegister,legalVatId,legalContactEmail,legalResponsiblePerson,legalSupervisoryAuthority,appVersion,reviewDemoEnabled);

@override
String toString() {
  return 'AppConfig(consentSheet: $consentSheet, passkeys: $passkeys, socialLoginApple: $socialLoginApple, socialLoginGoogle: $socialLoginGoogle, paywall: $paywall, accessibilityStatement: $accessibilityStatement, legalCompanyName: $legalCompanyName, legalAddress: $legalAddress, legalRegister: $legalRegister, legalVatId: $legalVatId, legalContactEmail: $legalContactEmail, legalResponsiblePerson: $legalResponsiblePerson, legalSupervisoryAuthority: $legalSupervisoryAuthority, appVersion: $appVersion, reviewDemoEnabled: $reviewDemoEnabled)';
}


}

/// @nodoc
abstract mixin class _$AppConfigCopyWith<$Res> implements $AppConfigCopyWith<$Res> {
  factory _$AppConfigCopyWith(_AppConfig value, $Res Function(_AppConfig) _then) = __$AppConfigCopyWithImpl;
@override @useResult
$Res call({
 bool consentSheet, bool passkeys, bool socialLoginApple, bool socialLoginGoogle, bool paywall, bool accessibilityStatement, String legalCompanyName, String legalAddress, String legalRegister, String legalVatId, String legalContactEmail, String legalResponsiblePerson, String legalSupervisoryAuthority, String appVersion, bool reviewDemoEnabled
});




}
/// @nodoc
class __$AppConfigCopyWithImpl<$Res>
    implements _$AppConfigCopyWith<$Res> {
  __$AppConfigCopyWithImpl(this._self, this._then);

  final _AppConfig _self;
  final $Res Function(_AppConfig) _then;

/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? consentSheet = null,Object? passkeys = null,Object? socialLoginApple = null,Object? socialLoginGoogle = null,Object? paywall = null,Object? accessibilityStatement = null,Object? legalCompanyName = null,Object? legalAddress = null,Object? legalRegister = null,Object? legalVatId = null,Object? legalContactEmail = null,Object? legalResponsiblePerson = null,Object? legalSupervisoryAuthority = null,Object? appVersion = null,Object? reviewDemoEnabled = null,}) {
  return _then(_AppConfig(
consentSheet: null == consentSheet ? _self.consentSheet : consentSheet // ignore: cast_nullable_to_non_nullable
as bool,passkeys: null == passkeys ? _self.passkeys : passkeys // ignore: cast_nullable_to_non_nullable
as bool,socialLoginApple: null == socialLoginApple ? _self.socialLoginApple : socialLoginApple // ignore: cast_nullable_to_non_nullable
as bool,socialLoginGoogle: null == socialLoginGoogle ? _self.socialLoginGoogle : socialLoginGoogle // ignore: cast_nullable_to_non_nullable
as bool,paywall: null == paywall ? _self.paywall : paywall // ignore: cast_nullable_to_non_nullable
as bool,accessibilityStatement: null == accessibilityStatement ? _self.accessibilityStatement : accessibilityStatement // ignore: cast_nullable_to_non_nullable
as bool,legalCompanyName: null == legalCompanyName ? _self.legalCompanyName : legalCompanyName // ignore: cast_nullable_to_non_nullable
as String,legalAddress: null == legalAddress ? _self.legalAddress : legalAddress // ignore: cast_nullable_to_non_nullable
as String,legalRegister: null == legalRegister ? _self.legalRegister : legalRegister // ignore: cast_nullable_to_non_nullable
as String,legalVatId: null == legalVatId ? _self.legalVatId : legalVatId // ignore: cast_nullable_to_non_nullable
as String,legalContactEmail: null == legalContactEmail ? _self.legalContactEmail : legalContactEmail // ignore: cast_nullable_to_non_nullable
as String,legalResponsiblePerson: null == legalResponsiblePerson ? _self.legalResponsiblePerson : legalResponsiblePerson // ignore: cast_nullable_to_non_nullable
as String,legalSupervisoryAuthority: null == legalSupervisoryAuthority ? _self.legalSupervisoryAuthority : legalSupervisoryAuthority // ignore: cast_nullable_to_non_nullable
as String,appVersion: null == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String,reviewDemoEnabled: null == reviewDemoEnabled ? _self.reviewDemoEnabled : reviewDemoEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
