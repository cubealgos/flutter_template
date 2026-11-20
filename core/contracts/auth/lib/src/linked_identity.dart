import 'package:auth/src/auth_service.dart';

/// One external identity linked to the current account (an OAuth
/// provider, most often) — the data behind the plan's "disconnect social
/// login" Settings → Account row.
class LinkedIdentity {
  /// Describes a linked identity.
  const LinkedIdentity({
    required this.id,
    required this.provider,
    this.providerEmail,
  });

  /// The backend's identity ID — pass this to
  /// [AuthService.unlinkIdentity] to disconnect it.
  final String id;

  /// The provider name, e.g. `'apple'` or `'google'`. A plain [String],
  /// not `OAuthProvider`: a backend may report a provider (or a future
  /// one an
  /// app links some other way) this closed enum doesn't cover, and losing
  /// that information here would make the Settings screen unable to even
  /// display it.
  final String provider;

  /// The email the provider reported for this identity, if any.
  final String? providerEmail;
}
