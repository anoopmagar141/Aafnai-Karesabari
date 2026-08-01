import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_user.dart';
import '../../data/repositories/user_repository.dart';

enum SelectedRole { farmer, consumer }

enum AuthStatus { unauthenticated, authenticated }

class OnboardingController extends ChangeNotifier {
  OnboardingController({
    FirebaseAuth? auth,
    UserRepository? userRepository,
    bool subscribeToAuthChanges = true,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _userRepository = userRepository ?? FirestoreUserRepository() {
    if (subscribeToAuthChanges) {
      _auth.authStateChanges().listen((user) {
        unawaited(_syncWithAuthState(user));
      });
    }
  }

  final FirebaseAuth _auth;
  final UserRepository _userRepository;
  String? languageCode;
  SelectedRole? role;
  String? email;

  bool profileComplete = false;
  bool isLoadingProfile = false;
  AuthStatus authStatus = AuthStatus.unauthenticated;

  bool get isComplete =>
      authStatus == AuthStatus.authenticated && profileComplete;

  Future<void> _syncWithAuthState(User? user) async {
    if (user == null) {
      authStatus = AuthStatus.unauthenticated;
      email = null;
      profileComplete = false;
      role = null;
      languageCode = null;
      notifyListeners();
      return;
    }

    authStatus = AuthStatus.authenticated;
    email = user.email;
    isLoadingProfile = true;
    notifyListeners();

    try {
      final profile = await _userRepository.read(user.uid);
      
      if (profile != null) {
        profileComplete = profile.profileCompleted;
        role = profile.role == UserRole.farmer
            ? SelectedRole.farmer
            : SelectedRole.consumer;
        languageCode = profile.language == AppLanguage.ne ? 'ne' : 'en';
      } else {
        profileComplete = false;
        role = null;
        languageCode = null;
      }
    } catch (e) {
      profileComplete = false;
    } finally {
      isLoadingProfile = false;
      notifyListeners();
    }
  }

  void selectLanguage(String value) {
    languageCode = value;
    notifyListeners();
  }

  void selectRole(SelectedRole value) {
    role = value;
    notifyListeners();
  }

  void authenticate(String userEmail) {
    email = userEmail;
    authStatus = AuthStatus.authenticated;
    // Do NOT notifyListeners here because _syncWithAuthState will handle the profile fetching and notification.
    // This avoids premature redirection to profile setup before the profile is actually loaded.
  }

  void signOut() {
    email = null;
    authStatus = AuthStatus.unauthenticated;
    profileComplete = false;
    notifyListeners();
  }

  void completeProfile() {
    profileComplete = true;
    notifyListeners();
  }

  void reset() {
    languageCode = null;
    role = null;
    email = null;
    profileComplete = false;
    authStatus = AuthStatus.unauthenticated;
    notifyListeners();
  }
}

OnboardingController? _onboardingControllerInstance;

OnboardingController get onboardingController =>
    _onboardingControllerInstance ??= OnboardingController();

final authStateProvider = ChangeNotifierProvider<OnboardingController>(
  (ref) => onboardingController,
);
