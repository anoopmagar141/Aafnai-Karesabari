import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/consumer/cart/cart_screen.dart';
import '../features/consumer/checkout/checkout_screen.dart';
import '../features/consumer/farmer_profile/farmer_profile_screen.dart';
import '../features/consumer/home/consumer_home_screen.dart';
import '../features/consumer/order_tracking/order_confirmation_screen.dart';
import '../features/consumer/order_tracking/order_tracking_screen.dart';
import '../features/consumer/product_detail/product_detail_screen.dart';
import '../features/consumer/search/search_screen.dart';
import '../features/farmer/earnings/earnings_screen.dart';
import '../features/farmer/home/farmer_home_screen.dart';
import '../features/farmer/listings/listing_flow_screens.dart';
import '../features/farmer/listings/listings_screen.dart';
import '../features/farmer/orders/farmer_orders_screen.dart';
import '../features/farmer/promotions/promotions_screen.dart';
import '../features/onboarding/auth/phone_auth_screen.dart';
import '../features/onboarding/language_select/language_select_screen.dart';
import '../features/onboarding/onboarding_controller.dart';
import '../features/onboarding/profile_setup/profile_setup_screen.dart';
import '../features/onboarding/role_select/role_select_screen.dart';
import '../features/onboarding/splash/splash_screen.dart';
import '../features/shared/notifications/notifications_screen.dart';
import '../features/shared/orders/order_detail_screen.dart';
import '../features/shared/reviews/reviews_screen.dart';
import '../features/shared/settings/settings_screen.dart';
import '../shared/components/bottom_nav_bar.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const languageSelect = '/language-select';
  static const roleSelect = '/role-select';
  static const login = '/auth/login';
  static const otp = '/auth/otp';
  static const farmerSetup = '/profile-setup/farmer';
  static const consumerSetup = '/profile-setup/consumer';
  static const farmerHome = '/farmer/home';
  static const consumerHome = '/consumer/home';
  static const cart = '/consumer/cart';
  static const product = '/consumer/product/:id';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  refreshListenable: onboardingController,
  redirect: (_, state) {
    final path = state.uri.path;
    if (path == AppRoutes.splash) return null;
    if (onboardingController.languageCode == null) return path == AppRoutes.languageSelect ? null : AppRoutes.languageSelect;
    if (onboardingController.role == null) return path == AppRoutes.roleSelect ? null : AppRoutes.roleSelect;
    if (!onboardingController.otpVerified) return path == AppRoutes.login || path == AppRoutes.otp ? null : AppRoutes.login;
    if (!onboardingController.profileComplete) {
      final setup = onboardingController.role == SelectedRole.farmer ? AppRoutes.farmerSetup : AppRoutes.consumerSetup;
      return path == setup ? null : setup;
    }
    if (path == AppRoutes.languageSelect || path == AppRoutes.roleSelect || path == AppRoutes.login || path == AppRoutes.otp || path == AppRoutes.farmerSetup || path == AppRoutes.consumerSetup) {
      return onboardingController.role == SelectedRole.farmer ? AppRoutes.farmerHome : AppRoutes.consumerHome;
    }
    return null;
  },
  routes: [
    GoRoute(path: '/', redirect: (_, __) => AppRoutes.splash),
    GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
    GoRoute(path: AppRoutes.languageSelect, builder: (_, __) => const LanguageSelectScreen()),
    GoRoute(path: AppRoutes.roleSelect, builder: (_, __) => const RoleSelectScreen()),
    GoRoute(path: AppRoutes.login, builder: (_, __) => const PhoneAuthScreen(otpStep: false)),
    GoRoute(path: AppRoutes.otp, builder: (_, __) => const PhoneAuthScreen(otpStep: true)),
    GoRoute(path: AppRoutes.farmerSetup, builder: (_, __) => const ProfileSetupScreen(role: SelectedRole.farmer)),
    GoRoute(path: AppRoutes.consumerSetup, builder: (_, __) => const ProfileSetupScreen(role: SelectedRole.consumer)),
    ShellRoute(builder: (_, __, child) => _RoleShell(farmer: true, child: child), routes: [
      GoRoute(path: AppRoutes.farmerHome, builder: (_, __) => const FarmerHomeScreen()),
      GoRoute(path: '/farmer/listings', builder: (_, __) => const ListingsScreen()),
      GoRoute(path: '/farmer/orders', builder: (_, __) => const FarmerOrdersScreen()),
      GoRoute(path: '/farmer/earnings', builder: (_, __) => const EarningsScreen()),
      GoRoute(path: '/farmer/promotions', builder: (_, __) => const PromotionsScreen()),
    ]),
    ShellRoute(builder: (_, __, child) => _RoleShell(farmer: false, child: child), routes: [
      GoRoute(path: AppRoutes.consumerHome, builder: (_, __) => const ConsumerHomeScreen()),
      GoRoute(path: '/consumer/search', builder: (_, __) => const SearchScreen()),
      GoRoute(path: AppRoutes.cart, builder: (_, __) => const CartScreen()),
      GoRoute(path: '/consumer/orders', builder: (_, __) => const OrderTrackingScreen()),
    ]),
    GoRoute(path: AppRoutes.product, builder: (_, state) => ProductDetailScreen(productId: state.pathParameters['id']!)),
    GoRoute(path: '/farmer/listings/add/photo', builder: (_, __) => const ListingFlowScreen(title: 'Add listing: photo', message: 'Photo upload will be added with Firebase Storage in Phase 3.')),
    GoRoute(path: '/farmer/listings/add/details', builder: (_, __) => const ListingFlowScreen(title: 'Add listing: details', message: 'Listing data entry will be added in Phase 3.')),
    GoRoute(path: '/farmer/listings/add/price', builder: (_, __) => const ListingFlowScreen(title: 'Add listing: price', message: 'Market-price reference will be added in Phase 3.')),
    GoRoute(path: '/farmer/listings/:id/edit', builder: (_, state) => ListingFlowScreen(title: 'Edit listing', message: 'Editing listing ${state.pathParameters['id']} will be added in Phase 3.')),
    GoRoute(path: '/farmer/orders/:id', builder: (_, state) => OrderDetailScreen(orderId: state.pathParameters['id']!, farmerView: true)),
    GoRoute(path: '/consumer/farmer/:id', builder: (_, __) => const FarmerProfileScreen()),
    GoRoute(path: '/consumer/checkout', builder: (_, __) => const CheckoutScreen()),
    GoRoute(path: '/consumer/order-confirmation', builder: (_, __) => const OrderConfirmationScreen()),
    GoRoute(path: '/consumer/orders/:id', builder: (_, state) => OrderDetailScreen(orderId: state.pathParameters['id']!, farmerView: false)),
    GoRoute(path: '/consumer/orders/:id/review', builder: (_, __) => const ReviewsScreen()),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
);

class _RoleShell extends StatelessWidget {
  const _RoleShell({required this.farmer, required this.child});
  final bool farmer;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final destinations = farmer ? const ['/farmer/home', '/farmer/listings', '/farmer/orders', '/farmer/earnings', '/settings'] : const ['/consumer/home', '/consumer/search', '/consumer/cart', '/consumer/orders', '/settings'];
    final currentPath = GoRouterState.of(context).uri.path;
    final index = destinations.indexOf(currentPath).clamp(0, destinations.length - 1).toInt();
    return Scaffold(body: child, bottomNavigationBar: AppBottomNavBar(farmer: farmer, index: index, onChanged: (next) => context.go(destinations[next])));
  }
}
