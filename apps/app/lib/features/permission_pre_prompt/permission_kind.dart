/// A system permission `PermissionPrePromptView` can explain before the
/// real (platform) prompt appears — push notifications, App Tracking
/// Transparency, and location, per the plan's "Permission pre-prompt
/// component" default screen.
enum PermissionKind {
  /// Push notifications.
  push,

  /// App Tracking Transparency (iOS).
  att,

  /// Location.
  location,
}
