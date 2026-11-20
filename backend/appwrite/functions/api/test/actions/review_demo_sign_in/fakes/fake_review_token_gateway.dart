import 'package:api/src/actions/review_demo_sign_in/review_token_gateway.dart';

/// An in-memory [ReviewTokenGateway] fake for testing `ReviewSignInService`
/// / `handleReviewDemoSignInRequest` without a live Appwrite instance.
class FakeReviewTokenGateway implements ReviewTokenGateway {
  /// Every user ID [createTokenFor] was called with, in order.
  final List<String> requestedUserIds = <String>[];

  /// If set, [createTokenFor] throws this instead of succeeding.
  Exception? error;

  @override
  Future<ReviewSessionToken> createTokenFor(String userId) async {
    final failure = error;
    if (failure != null) throw failure;

    requestedUserIds.add(userId);

    return ReviewSessionToken(userId: userId, secret: 'fake-secret-$userId');
  }
}
