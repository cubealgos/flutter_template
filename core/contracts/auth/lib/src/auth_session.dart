import 'package:auth/src/auth_service.dart';
import 'package:meta/meta.dart';

/// The signed-in user for the current [AuthService] session.
///
/// Intentionally small: just enough for a screen to greet the user and
/// pass [userId] to `core/contracts/data` repositories and
/// `backend/appwrite/adapters`'s function calls. Anything product-specific
/// (a display name, an avatar) belongs in an app's own profile model
/// (`packages/domain`'s `UserProfile`), not here.
@immutable
class AuthSession {
  /// Creates a session for [userId].
  const AuthSession({required this.userId, this.email});

  /// The backend's user ID (e.g. Appwrite's `$id`).
  final String userId;

  /// The user's email, if this session has one. Null for an identity type
  /// with no email (e.g. a passkey session, or a phone-only one an app
  /// adds later).
  final String? email;

  @override
  int get hashCode => Object.hash(userId, email);

  @override
  bool operator ==(Object other) =>
      other is AuthSession && other.userId == userId && other.email == email;

  @override
  String toString() => 'AuthSession(userId: $userId, email: $email)';
}
