import 'package:flutter/foundation.dart';

enum SelectedRole { farmer, consumer }

/// Temporary client-side flow state until Firebase Auth/profile storage arrives.
class OnboardingController extends ChangeNotifier {
  String? languageCode;
  SelectedRole? role;
  bool otpVerified = false;
  bool profileComplete = false;

  bool get isComplete => languageCode != null && role != null && otpVerified && profileComplete;
  void selectLanguage(String value) { languageCode = value; notifyListeners(); }
  void selectRole(SelectedRole value) { role = value; notifyListeners(); }
  void verifyOtp() { otpVerified = true; notifyListeners(); }
  void completeProfile() { profileComplete = true; notifyListeners(); }
}

final onboardingController = OnboardingController();
