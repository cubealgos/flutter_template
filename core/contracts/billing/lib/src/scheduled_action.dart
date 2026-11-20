/// A change the provider has scheduled for a subscription.
enum ScheduledAction {
  /// The subscription will be canceled.
  cancel,

  /// The subscription will be paused.
  pause,

  /// The subscription will resume.
  resume;

  /// The action named [name], or null.
  static ScheduledAction? fromName(Object? name) {
    for (final action in values) {
      if (action.name == name) return action;
    }

    return null;
  }
}
