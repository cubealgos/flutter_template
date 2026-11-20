import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// A placeholder profile model, standing in for whatever real per-user
/// profile shape a cloned app actually needs.
///
/// This model exists so `packages/domain` ships at least one example of a
/// model an app owns end to end: referenced by the app's UI, persisted via
/// `TablesDB`, and (if an app chooses to expose it) readable from a
/// Function. **Apps are expected to replace this model outright** — add the
/// real fields the product needs, or delete it if nothing in the app needs
/// a shared profile shape — rather than growing it in place. It is not part
/// of any function's ownership/deletion logic in
/// `backend/appwrite/schema`'s `templateSchema`.
@freezed
abstract class UserProfile with _$UserProfile {
  /// Creates a placeholder user profile.
  const factory UserProfile({
    /// The Appwrite user ID this profile belongs to.
    required String userId,

    /// A display name, however the app defines one.
    required String displayName,
  }) = _UserProfile;

  /// Deserializes a [UserProfile] from JSON (e.g. a `TablesDB` row).
  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
