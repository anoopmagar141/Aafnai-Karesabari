import '../features/onboarding/onboarding_controller.dart';

abstract final class AppRoutes {
  static const landing = '/';
  static const splash = '/splash';
  static const languageSelect = '/language-select';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const consumerSetup = '/profile-setup/consumer';
  static const consumerHome = '/consumer/home';
  static const farmerSetup = '/profile-setup/farmer';
  static const farmerHome = '/farmer/home';
  static const sellerApply = '/seller/apply';
  static const editProfile = '/profile/edit';
  static const checkout = '/consumer/checkout';
  static const orderConfirmation = '/consumer/order-confirmation';
  static const consumerOrders = '/consumer/orders';
  static const notifications = '/notifications';
  static const cart = '/consumer/cart';
  static const wishlist = '/consumer/wishlist';
  static const product = '/consumer/product/:id';
  static const adminDashboard = '/admin/dashboard';
  static const adminSellerApplications = '/admin/seller-applications';
}

String? resolveRedirectPath({
  required String path,
  required OnboardingController onboardingController,
}) {
  // Landing and splash handling
  if (path == AppRoutes.landing || path == AppRoutes.splash) {
    // Authenticated users go straight to home
    if (onboardingController.authStatus == AuthStatus.authenticated) {
      return AppRoutes.consumerHome;
    }
    // If language is already selected, skip Welcome and go to Login
    if (onboardingController.languageCode != null) {
      return AppRoutes.login;
    }
    // Unauthenticated users on first launch stay on landing/splash
    return null;
  }

  // The persisted language preference loads asynchronously from
  // SharedPreferences. On a page refresh, languageCode starts out null in
  // memory even for a returning user who already picked one — deciding
  // anything based on languageCode before that load finishes would
  // incorrectly bounce the user back into the language-select/register
  // funnel. Wait for it; onboardingController notifies listeners (which
  // re-runs this redirect) once it resolves.
  if (onboardingController.isLoadingLanguage) {
    return null;
  }

  // Language selection is required before the "Get started" -> register
  // funnel, but NOT before signing in: a returning user's language
  // preference already lives on their profile and loads right after
  // authentication (see syncWithAuthState). Without this exception, any
  // user who hasn't picked a language yet — which is every first-time
  // visitor by definition — gets forced into language-select/register
  // no matter which button they pressed on the splash screen.
  final skipsLanguageGate =
      path == AppRoutes.login || path == AppRoutes.forgotPassword;
  if (onboardingController.languageCode == null && !skipsLanguageGate) {
    return AppRoutes.languageSelect;
  }

  // Unauthenticated users: only auth routes are allowed. languageSelect is
  // included so "Get started" can always reach it (and from there,
  // register) even when a language was already picked in a previous
  // session — otherwise it and "I already have an account" both collapse
  // onto the login screen.
  if (onboardingController.authStatus == AuthStatus.unauthenticated) {
    final isAuthRoute = path == AppRoutes.login ||
        path == AppRoutes.register ||
        path == AppRoutes.forgotPassword ||
        path == AppRoutes.languageSelect;
    return isAuthRoute ? null : AppRoutes.login;
  }

  // Authenticated users: special case for login route -> redirect to home
  if (path == AppRoutes.login) {
    return AppRoutes.consumerHome;
  }

   // Profile not complete – only force setup for routes that need identity/delivery information
   if (!onboardingController.profileComplete) {
     const protectedRoutes = {
       AppRoutes.consumerSetup,
       AppRoutes.cart,
       AppRoutes.checkout,
       AppRoutes.orderConfirmation,
       AppRoutes.farmerSetup,
     };
     if (protectedRoutes.contains(path)) {
       return AppRoutes.consumerSetup;
     }
   }

  // While loading profile keep current screen
  if (onboardingController.isLoadingProfile) {
    return null;
  }

  // Prevent navigating back to onboarding screens after setup
  if (path == AppRoutes.languageSelect ||
      path == AppRoutes.register ||
      path == AppRoutes.forgotPassword ||
      path == AppRoutes.consumerSetup) {
    return AppRoutes.consumerHome;
  }

  // The seller dashboard/listings/orders/earnings flow lives under /farmer/
  // and requires an approved seller account. The application form itself
  // lives under /seller/ — that's precisely where a not-yet-approved user
  // needs to land, so it's excluded from this guard. Admins are exempt too:
  // the "Seed Sample Listings" action creates listings owned by the admin's
  // own uid, so an admin needs to reach /farmer/orders to accept/reject
  // orders placed against that catalog — otherwise those orders would have
  // no one able to act on them at all.
  final isFarmerRoute = path.startsWith('/farmer/');
  if (isFarmerRoute &&
      !onboardingController.sellerApproved &&
      !onboardingController.isAdmin) {
    return AppRoutes.consumerHome;
  }

  // Admin routes require admin status
  final isAdminRoute = path.startsWith('/admin/');
  if (isAdminRoute && !onboardingController.isAdmin) {
    return AppRoutes.consumerHome;
  }

  // All other routes are allowed
  return null;
} 
