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
  static const sellerDashboard = '/seller/dashboard';
  static const sellerListings = '/seller/listings';
  static const sellerListingsCreate = '/seller/listings/add';
  static const sellerListingsEdit = '/seller/listings/:id/edit';
  static const sellerOrders = '/seller/orders';
  static const sellerEarnings = '/seller/earnings';
  static const sellerProfile = '/seller/profile';
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

  // Language selection must be completed first
  if (onboardingController.languageCode == null) {
    return AppRoutes.languageSelect;
  }

  // Unauthenticated users: only auth routes are allowed
  if (onboardingController.authStatus == AuthStatus.unauthenticated) {
    final isAuthRoute = path == AppRoutes.login ||
        path == AppRoutes.register ||
        path == AppRoutes.forgotPassword;
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

  // Seller routes require approval
  final isSellerRoute = path.startsWith('/seller/');
  if (isSellerRoute && !onboardingController.sellerApproved) {
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
