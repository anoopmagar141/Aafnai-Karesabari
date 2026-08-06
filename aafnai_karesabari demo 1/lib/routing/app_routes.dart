import '../features/onboarding/onboarding_controller.dart';

abstract final class AppRoutes {
  static const landing = '/';
  static const splash = '/splash';
  static const languageSelect = '/language-select';
  static const roleSelect = '/role-select';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const farmerSetup = '/profile-setup/farmer';
  static const consumerSetup = '/profile-setup/consumer';
  static const farmerHome = '/farmer/home';
  static const consumerHome = '/consumer/home';
  static const cart = '/consumer/cart';
  static const checkout = '/consumer/checkout';
  static const orderConfirmation = '/consumer/order-confirmation';
  static const consumerOrders = '/consumer/orders';
  static const notifications = '/notifications';
  static const product = '/consumer/product/:id';
}

String? resolveRedirectPath({
  required String path,
  required OnboardingController onboardingController,
}) {
  // Keep the landing screen visible until the user chooses to continue.
  if (path == AppRoutes.landing || path == AppRoutes.splash) return null;

  final isAuthRoute = path == AppRoutes.login ||
      path == AppRoutes.register ||
      path == AppRoutes.forgotPassword;

  // Unauthenticated users should be sent to login unless they are on an auth route
  if (onboardingController.authStatus == AuthStatus.unauthenticated) {
    return isAuthRoute ? null : AppRoutes.login;
  }

  // Prevent navigation while fetching profile data from Firestore
  if (onboardingController.isLoadingProfile) {
    return null; // Stay on current route while loading
  }

  if (onboardingController.languageCode == null) {
    return path == AppRoutes.languageSelect ? null : AppRoutes.languageSelect;
  }
  if (onboardingController.role == null) {
    return path == AppRoutes.roleSelect ? null : AppRoutes.roleSelect;
  }
  if (!onboardingController.profileComplete) {
    final isSetupRoute = path == AppRoutes.farmerSetup || path == AppRoutes.consumerSetup;
    if (isSetupRoute) return null;

    final setup = onboardingController.role == SelectedRole.farmer
        ? AppRoutes.farmerSetup
        : AppRoutes.consumerSetup;

    if (onboardingController.authStatus == AuthStatus.authenticated) {
      if (isAuthRoute) {
        return onboardingController.role == SelectedRole.farmer
            ? AppRoutes.farmerHome
            : AppRoutes.consumerHome;
      }
      return null;
    }

    // Allow unauthenticated users to complete setup before continuing.
    return path == setup ? null : setup;
  }

  if (path == AppRoutes.languageSelect ||
      path == AppRoutes.roleSelect ||
      path == AppRoutes.login ||
      path == AppRoutes.register ||
      path == AppRoutes.forgotPassword ||
      path == AppRoutes.farmerSetup ||
      path == AppRoutes.consumerSetup) {
    return onboardingController.role == SelectedRole.farmer
        ? AppRoutes.farmerHome
        : AppRoutes.consumerHome;
  }

  return null;
}
