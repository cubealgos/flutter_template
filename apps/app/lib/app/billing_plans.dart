/// The plan key the paywall sells.
///
/// It must be a key of the `api` Function's `PADDLE_PLANS` variable (plan key
/// to Paddle price ID). A clone with several plans replaces this with its own
/// list and lets the paywall choose; the template sells one.
const String defaultBillingPlan = 'pro';
