import 'package:auth/src/auth_service.dart';

/// A pending email sign-in code, returned by
/// [AuthService.requestEmailCode] and handed back to
/// [AuthService.verifyEmailCode] once the user enters the code.
///
/// Carries exactly the same shape whether or not an account already
/// existed for the requested email — see [AuthService.requestEmailCode]'s
/// dartdoc for why that matters.
class EmailCodeRequest {
  /// Creates a pending code request for [userId]/[email].
  const EmailCodeRequest({required this.userId, required this.email});

  /// The backend's user ID this code was issued for. Opaque to callers —
  /// pass it straight back to [AuthService.verifyEmailCode].
  final String userId;

  /// The email address the code was sent to.
  final String email;
}
