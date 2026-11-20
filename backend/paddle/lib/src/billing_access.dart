import 'package:billing/billing.dart';

/// Who may do what for an owner. The caller's identity is the router's
/// `x-appwrite-user-id`, never the request body.
abstract interface class BillingAccess {
  /// Whether [userId] may start a checkout for, change or open the portal of
  /// [owner]: the user itself, or an admin or the owner of the team.
  Future<bool> mayManage(String userId, BillingOwner owner);

  /// Whether [userId] may read [owner]'s entitlement: the user itself, or any
  /// member of the team.
  Future<bool> mayRead(String userId, BillingOwner owner);
}
