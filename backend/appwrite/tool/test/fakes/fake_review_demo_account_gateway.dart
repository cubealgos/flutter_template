import 'package:appwrite_tool/src/review_demo_account_gateway.dart';

/// An in-memory [ReviewDemoAccountGateway] fake for testing
/// `seedReviewDemoAccount` without a live Appwrite instance.
class FakeReviewDemoAccountGateway implements ReviewDemoAccountGateway {
  final Map<String, String> _userIdByEmail = <String, String>{};
  final Map<String, Map<String, String>> _variablesByFunction =
      <String, Map<String, String>>{};

  /// Every user ID [verifyEmail] was called with, in order - lets a test
  /// assert a newly created account was also verified.
  final List<String> verifiedUserIds = <String>[];

  /// The next user ID [createUser] returns.
  int _nextId = 0;

  /// Seeds an existing account for [email]/[userId] before a test runs -
  /// models an already-seeded review demo account.
  void seedExisting({required String email, required String userId}) {
    _userIdByEmail[email] = userId;
  }

  /// Seeds an existing function variable before a test runs.
  void seedFunctionVariable({
    required String functionId,
    required String key,
    required String value,
  }) {
    _variablesByFunction.putIfAbsent(
      functionId,
      () => <String, String>{},
    )[key] = value;
  }

  /// The current value of function [functionId]'s variable [key], or null.
  String? functionVariable({required String functionId, required String key}) =>
      _variablesByFunction[functionId]?[key];

  @override
  Future<String?> findUserIdByEmail(String email) async =>
      _userIdByEmail[email];

  @override
  Future<String> createUser({required String email}) async {
    final userId = 'demo-user-${_nextId++}';
    _userIdByEmail[email] = userId;

    return userId;
  }

  @override
  Future<void> verifyEmail(String userId) async {
    verifiedUserIds.add(userId);
  }

  @override
  Future<bool> functionVariableHasValue({
    required String functionId,
    required String key,
  }) async =>
      _variablesByFunction[functionId]?[key]?.trim().isNotEmpty ?? false;

  @override
  Future<void> setFunctionVariable({
    required String functionId,
    required String key,
    required String value,
  }) async {
    _variablesByFunction.putIfAbsent(
      functionId,
      () => <String, String>{},
    )[key] = value;
  }
}
