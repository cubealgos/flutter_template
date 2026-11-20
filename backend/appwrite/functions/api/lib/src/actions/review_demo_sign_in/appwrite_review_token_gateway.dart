import 'package:api/src/actions/review_demo_sign_in/review_token_gateway.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

/// The real [ReviewTokenGateway], backed by `package:dart_appwrite`'s
/// `Users` service.
class AppwriteReviewTokenGateway implements ReviewTokenGateway {
  /// Creates a gateway backed by [client].
  ///
  /// [client] should be built with this execution's own per-run API key
  /// (the `x-appwrite-key` request header — see `lib/main.dart`), the same
  /// pattern `delete_account`'s `AppwriteAccountDeletionGateway` uses, not
  /// a long-lived server key.
  AppwriteReviewTokenGateway(Client client) : _users = Users(client);

  final Users _users;

  @override
  Future<ReviewSessionToken> createTokenFor(String userId) async {
    final token = await _users.createToken(userId: userId);

    return ReviewSessionToken(userId: token.userId, secret: token.secret);
  }
}
