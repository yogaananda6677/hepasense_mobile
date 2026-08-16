sealed class PasswordChangeState {
  const PasswordChangeState();
}

class PasswordChangeIdle extends PasswordChangeState {
  const PasswordChangeIdle();
}

class PasswordChangeSubmitting extends PasswordChangeState {
  const PasswordChangeSubmitting();
}

class PasswordChangeFailure extends PasswordChangeState {
  const PasswordChangeFailure(this.message);
  final String message;
}

class PasswordChangeSuccess extends PasswordChangeState {
  const PasswordChangeSuccess(this.message);
  final String message;
}
