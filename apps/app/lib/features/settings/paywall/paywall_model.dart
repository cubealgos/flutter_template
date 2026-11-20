import 'package:billing/billing.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mvc/mvc.dart';

part 'paywall_model.freezed.dart';

/// `PaywallView`'s view model: the entitlement the server computed, the
/// quantity the user is choosing, and whether a call is running or failed.
@freezed
abstract class PaywallModel with _$PaywallModel implements ViewModel {
  /// Creates the model.
  const factory PaywallModel({
    /// The owner's entitlement, or null until it has loaded (or when nobody
    /// is signed in).
    Entitlement? entitlement,

    /// The quantity to subscribe to, or to change to (units: monitored
    /// sites, seats, ...).
    @Default(1) int quantity,

    /// Whether the entitlement is still loading.
    @Default(true) bool loading,

    /// Whether a checkout, portal or quantity call is running.
    @Default(false) bool busy,

    /// Whether the last call failed.
    @Default(false) bool failed,

    /// Whether nobody is signed in, so there is nobody to bill.
    @Default(false) bool signedOut,
  }) = _PaywallModel;
}
