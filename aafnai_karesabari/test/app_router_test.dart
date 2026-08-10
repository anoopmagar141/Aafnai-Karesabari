import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:aafnai_karesabari/data/models/app_user.dart';
import 'package:aafnai_karesabari/data/repositories/user_repository.dart';
import 'package:aafnai_karesabari/features/onboarding/onboarding_controller.dart';
import 'package:aafnai_karesabari/routing/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUserRepository implements UserRepository {
  @override
  Future<AppUser> create(AppUser user) async => user;

  @override
  Future<void> update(AppUser user) async {}

  @override
  Future<void> delete(String userId) async {}

  @override
  Future<AppUser?> getById(String userId) async => null;

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
  return OnboardingController(
    auth: MockFirebaseAuth(),
    userRepository: FakeUserRepository(),
    subscribeToAuthChanges: false,
  );
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

    test('redirects a non-approved user away from other seller routes', () {
      final controller = createTestOnboardingController();
      controller.authStatus = AuthStatus.authenticated;
      controller.selectLanguage('en');
      controller.profileComplete = true;

      final redirect = resolveRedirectPath(
        path: AppRoutes.sellerDashboard,
        onboardingController: controller,
      );

      expect(redirect, AppRoutes.consumerHome);
    });
  });
}
