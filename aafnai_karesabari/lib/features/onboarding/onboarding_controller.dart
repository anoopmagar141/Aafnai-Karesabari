import 'dart:async';
// import removed: unused
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_user.dart';
import '../../data/repositories/user_repository.dart';

enum AuthStatus { unauthenticated, authenticated }

class OnboardingController extends ChangeNotifier {
  OnboardingController({
    FirebaseAuth? auth,
    UserRepository? userRepository,
    bool subscribeToAuthChanges = true,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _userRepository = userRepository ?? FirestoreUserRepository() {
    _loadPersistedLanguage();
    if (subscribeToAuthChanges) {
      _auth.authStateChanges().listen((user) {
        unawaited(syncWithAuthState(user));
      });
    }
  }

  final FirebaseAuth _auth;
  final UserRepository _userRepository;

  String? uid;
  String? email;
  String? languageCode;
  bool profileComplete = false;
  static const adminDashboard = '/admin/dashboard';
  static const adminSellerApplications = '/admin/seller-applications';
  // Seller section routes
  static const sellerDashboard = '/seller/dashboard';
  static const sellerListings = '/seller/listings';
  static const sellerListingsCreate = '/seller/listings/create';
  static const sellerListingsEdit = '/seller/listings/edit/:id';
  static const sellerOrders = '/seller/orders';
  static const sellerEarnings = '/seller/earnings';
  // Internal admin flag
  bool _isAdmin = false;
  // Internal seller status
  String _sellerStatus = 'none';
  // Seller status getter
  String get sellerStatus => _sellerStatus;
  // Admin getter
  bool get isAdmin => _isAdmin;
bool get isSeller => _sellerStatus != 'none';
bool get sellerApproved => _sellerStatus == 'approved';

  // Switch active role and persist to Firestore
  Future<void> switchRole(String role) async {
    if (uid == null) return;
    activeRole = role;
    await _userRepository.updateActiveRole(uid!, role);
  }

  bool isLoadingProfile = false;
  AuthStatus authStatus = AuthStatus.unauthenticated; // updated once Firebase confirms auth state
  // Active role for buyer/seller mode
  String _activeRole = 'buyer';

  String get activeRole => _activeRole;
  set activeRole(String value) {
    _activeRole = value;
    notifyListeners();
  }

  bool get isComplete =>
      authStatus == AuthStatus.authenticated && profileComplete;

  bool _isSyncing = false;

  Future<void> syncWithAuthState(User? user) async {
    if (_isSyncing) return;
    _isSyncing = true;
    
    if (user == null) {
      authStatus = AuthStatus.unauthenticated;
      email = null;
      profileComplete = false;
      _isAdmin = false;
      languageCode = null;
      _isSyncing = false;
      notifyListeners();
      return;
    }

    authStatus = AuthStatus.authenticated;
    uid = user.uid;
    email = user.email;
    isLoadingProfile = true;
    notifyListeners();

    try {
      // Attempt to read the user profile; if it does not exist, create a minimal one
      AppUser? profile = await _userRepository.read(user.uid).timeout(const Duration(seconds: 5), onTimeout: () => null);
        if (profile == null) {
          // Create a minimal user document so that subsequent reads succeed
          final minimal = AppUser(
            id: user.uid,
            email: user.email ?? '',
            phone: '',
            name: '',
            location: null,
            language: AppLanguage.en,
            profileCompleted: false,
            createdAt: DateTime.now(),
          );
          await _userRepository.create(minimal);
          profile = minimal;
        }

        // Update onboarding flags from the profile (profile is guaranteed non‑null here)
        final p = profile;
        profileComplete = p.profileCompleted || (p.name.isNotEmpty && p.location != null && p.location!.isNotEmpty);
        _isAdmin = p.isAdmin;
        // Set active role from user data
        activeRole = p.activeRole;
        _sellerStatus = p.sellerStatus;

        // Preserve languageCode if already selected; otherwise fallback to stored language
        languageCode ??= p.language == AppLanguage.ne ? 'ne' : 'en';
    } catch (e) {
      profileComplete = false;
    } finally {
      isLoadingProfile = false;
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Re-reads the current user's Firestore profile so flags like
  /// sellerStatus reflect the latest state without requiring a re-login.
  Future<void> refreshProfile() async {
    await syncWithAuthState(_auth.currentUser);
  }

  Future<void> selectLanguage(String value) async {
    languageCode = value;
    // Persist language selection so it only appears on first launch
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('languageCode', value);
    } catch (e) {
      // ignore storage errors; fallback to in‑memory only
    }
    notifyListeners();
  }

  void signOut() {
    email = null;
    authStatus = AuthStatus.unauthenticated;
    profileComplete = false;
    _isAdmin = false;
    notifyListeners();
  }

  void completeProfile() {
    profileComplete = true;
    notifyListeners();
  }

  Future<void> _loadPersistedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('languageCode');
      if (stored != null && stored.isNotEmpty) {
        languageCode = stored;
      }
    } catch (e) {
      // ignore errors; languageCode will remain null and be asked again
    }
    // Ensure listeners know the language state (may affect initial redirect)
    notifyListeners();
  }

  void reset() {
    languageCode = null;
    email = null;
    profileComplete = false;
    _isAdmin = false;
    authStatus = AuthStatus.unauthenticated;
    activeRole = 'buyer';
    _sellerStatus = 'none';
    notifyListeners();
  }
}

OnboardingController? _onboardingControllerInstance;

OnboardingController get onboardingController =>
    _onboardingControllerInstance ??= OnboardingController();

final authStateProvider = ChangeNotifierProvider<OnboardingController>(
  (ref) => onboardingController,
);
