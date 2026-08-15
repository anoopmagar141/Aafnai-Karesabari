/// Tunable rules for the simulated phone-OTP login flow: code length,
/// how long a code stays valid, and resend throttling.
abstract final class AuthPolicy {
  static const otpLength = 4;
  static const otpExpiry = Duration(minutes: 5);
  static const resendCooldown = Duration(seconds: 30);
  static const maxResendsPerSession = 3;
}
