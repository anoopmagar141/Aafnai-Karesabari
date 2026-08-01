import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:hamro_karesabari/data/models/app_user.dart';
import 'package:hamro_karesabari/data/repositories/user_repository.dart';
import 'package:hamro_karesabari/features/onboarding/onboarding_controller.dart';
import 'package:hamro_karesabari/routing/app_routes.dart';
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
      controller.selectRole(SelectedRole.consumer);

      final redirect = resolveRedirectPath(
        path: AppRoutes.consumerSetup,
        onboardingController: controller,
      );

      expect(redirect, AppRoutes.login);
    });

    test('allows the login route for unauthenticated users', () {
      final controller = createTestOnboardingController();
      controller.selectLanguage('en');
      controller.selectRole(SelectedRole.consumer);

      final redirect = resolveRedirectPath(
        path: AppRoutes.login,
        onboardingController: controller,
      );

      expect(redirect, isNull);
    });
  });
}
