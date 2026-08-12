import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:aafnai_karesabari/data/models/app_user.dart';
import 'package:aafnai_karesabari/data/repositories/user_repository.dart';
import 'package:aafnai_karesabari/features/onboarding/onboarding_controller.dart';
import 'package:aafnai_karesabari/routing/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUserRepository implements UserRepository {
  FakeUserRepository({this.profile});

  /// When set, getById returns this regardless of the requested id — enough
  /// for tests that need syncWithAuthState to populate isAdmin/profile
  /// fields from a known profile.
  final AppUser? profile;

  @override
  Future<AppUser> create(AppUser user) async => user;

  @override
  Future<void> update(AppUser user) async {}

  @override
  Future<void> delete(String userId) async {}

  @override
  Future<AppUser?> getById(String userId) async => profile;

  @override
  Stream<AppUser?> stream(String userId) async* {
    yield null;
  }

  @override
  Future<List<AppUser>> list({int? limit}) async => const [];

  @override
  Future<AppUser?> findByPhone(String phone) async => null;

  @override
  Future<void> updateActiveRole(String uid, String role) async {}

  @override
  Future<void> updateSellerStatus(String uid, String status) async {}
}

OnboardingController createTestOnboardingController() {
  // The real controller loads its persisted language preference from
  // SharedPreferences asynchronously, which never resolves in this plain
  // `test()` environment (no plugin bindings). Mark it loaded immediately
  // so resolveRedirectPath's isLoadingLanguage gate doesn't block every
  // test case forever.
  return OnboardingController(
    auth: MockFirebaseAuth(),
    userRepository: FakeUserRepository(),
    subscribeToAuthChanges: false,
  )..isLoadingLanguage = false;
}

void main() {
  group('resolveRedirectPath', () {
    test('redirects unauthenticated users to login', () {
      final controller = createTestOnboardingController();
      controller.selectLanguage('en');
      // Role selection removed; no longer needed

      final redirect = resolveRedirectPath(
        path: AppRoutes.consumerSetup,
        onboardingController: controller,
      );

      expect(redirect, AppRoutes.login);
    });

    test('allows the landing route for unauthenticated users', () {
      final controller = createTestOnboardingController();

      final redirect = resolveRedirectPath(
        path: AppRoutes.landing,
        onboardingController: controller,
      );

      expect(redirect, isNull);
    });

    test('allows the login route for unauthenticated users', () {
      final controller = createTestOnboardingController();
      controller.selectLanguage('en');
      // Role selection removed; no longer needed

      final redirect = resolveRedirectPath(
        path: AppRoutes.login,
        onboardingController: controller,
      );

      expect(redirect, isNull);
    });

    test('redirects authenticated users off login when profile is incomplete', () {
      final controller = createTestOnboardingController();
      controller.authStatus = AuthStatus.authenticated;
      controller.selectLanguage('en');
      // role selection removed (no longer needed)
      controller.profileComplete = false;

      final redirect = resolveRedirectPath(
        path: AppRoutes.login,
        onboardingController: controller,
      );

      expect(redirect, AppRoutes.consumerHome);
    });

    test('allows a non-approved user to reach the seller application form', () {
      final controller = createTestOnboardingController();
      controller.authStatus = AuthStatus.authenticated;
      controller.selectLanguage('en');
      controller.profileComplete = true;

      final redirect = resolveRedirectPath(
        path: AppRoutes.sellerApply,
        onboardingController: controller,
      );

      expect(redirect, isNull);
    });

    test('redirects a non-approved user away from the farmer dashboard', () {
      final controller = createTestOnboardingController();
      controller.authStatus = AuthStatus.authenticated;
      controller.selectLanguage('en');
      controller.profileComplete = true;

      final redirect = resolveRedirectPath(
        path: AppRoutes.farmerHome,
        onboardingController: controller,
      );

      expect(redirect, AppRoutes.consumerHome);
    });

    test('"Get started" reaches language select even with a cached language, unlike "I already have an account"', () {
      final controller = createTestOnboardingController();
      controller.selectLanguage('en'); // simulates a language cached from a previous session

      final getStarted = resolveRedirectPath(
        path: AppRoutes.languageSelect,
        onboardingController: controller,
      );
      final alreadyHaveAccount = resolveRedirectPath(
        path: AppRoutes.login,
        onboardingController: controller,
      );

      expect(getStarted, isNull, reason: 'Get started must show language select, not bounce to login');
      expect(alreadyHaveAccount, isNull, reason: 'Sign-in should go straight to the login screen');
    });

    test('waits for the persisted language check instead of forcing language select', () {
      // Simulates a page refresh: languageCode is null in memory even though
      // a returning user already picked one, because the SharedPreferences
      // read hasn't resolved yet.
      final controller = createTestOnboardingController();
      controller.isLoadingLanguage = true;

      final redirect = resolveRedirectPath(
        path: AppRoutes.register,
        onboardingController: controller,
      );

      expect(redirect, isNull,
          reason: 'Must not redirect away while the language preference is still loading');
    });

    test('a first-time visitor (no language ever chosen) can still reach sign-in directly', () {
      // languageCode is null and stays null — nobody has picked one yet,
      // as is true for every genuinely first-time visitor.
      final controller = createTestOnboardingController();

      final signIn = resolveRedirectPath(
        path: AppRoutes.login,
        onboardingController: controller,
      );
      final register = resolveRedirectPath(
        path: AppRoutes.register,
        onboardingController: controller,
      );

      expect(signIn, isNull,
          reason: '"I already have an account" must show sign-in even with no language chosen yet');
      expect(register, AppRoutes.languageSelect,
          reason: 'Register still requires picking a language first');
    });

    test('an admin (not an approved seller) can still reach /farmer/* to manage the seeded catalog\'s orders', () async {
      final mockUser = MockUser(uid: 'admin-1', email: 'admin@test.com');
      final controller = OnboardingController(
        auth: MockFirebaseAuth(),
        userRepository: FakeUserRepository(
          profile: AppUser(
            id: 'admin-1',
            name: 'Admin',
            phone: '',
            language: AppLanguage.en,
            email: 'admin@test.com',
            createdAt: DateTime(2026, 1, 1),
            profileCompleted: true,
            isAdmin: true,
            // Deliberately not an approved seller — the admin's bypass
            // must not depend on also applying to sell.
            sellerStatus: 'none',
          ),
        ),
        subscribeToAuthChanges: false,
      )..isLoadingLanguage = false;
      controller.selectLanguage('en');
      await controller.syncWithAuthState(mockUser);

      final redirect = resolveRedirectPath(
        path: AppRoutes.farmerHome,
        onboardingController: controller,
      );

      expect(redirect, isNull);
    });
  });
}
