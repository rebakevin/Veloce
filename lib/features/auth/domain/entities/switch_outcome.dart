/// How an account switch ended when nothing technically failed.
enum SwitchOutcome {
  /// The target account is now signed in.
  switched,

  /// The stored sign-in is gone or expired. The UI asks the user to sign in
  /// again (email form, or the Google chooser).
  signInRequired,
}
