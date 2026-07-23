abstract final class AuthPolicy {
  static const otpLength = 4;
  static const otpExpiry = Duration(minutes: 5);
  static const resendCooldown = Duration(seconds: 30);
  static const maxResendsPerSession = 3;
}
