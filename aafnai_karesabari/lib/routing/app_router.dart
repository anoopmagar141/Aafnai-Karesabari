import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routing/app_routes.dart';
import '../features/onboarding/onboarding_controller.dart';
import '../features/onboarding/splash/splash_screen.dart';

import '../data/models/listing.dart';

import '../features/consumer/checkout/checkout_screen.dart';
import '../features/consumer/farmer_profile/farmer_profile_screen.dart';
import '../features/consumer/home/consumer_home_screen.dart';
import '../features/consumer/order_tracking/order_confirmation_screen.dart';
import '../features/consumer/order_tracking/order_tracking_screen.dart';
import '../features/consumer/cart/cart_screen.dart';
import '../features/consumer/product_detail/product_detail_screen.dart';
import '../features/consumer/search/search_screen.dart';
import '../features/farmer/earnings/earnings_screen.dart';
import '../features/farmer/home/farmer_home_screen.dart';
import '../features/farmer/listings/listing_form_screen.dart';
import '../features/farmer/listings/listings_screen.dart';
import '../features/farmer/orders/farmer_orders_screen.dart';
import '../features/farmer/promotions/promotions_screen.dart';
import '../features/onboarding/auth/forgot_password_screen.dart';
import '../features/onboarding/auth/login_screen.dart';
import '../features/onboarding/auth/register_screen.dart';
import '../features/onboarding/language_select/language_select_screen.dart';
import '../features/onboarding/profile_setup/profile_setup_screen.dart';
import '../features/admin/dashboard/admin_dashboard_screen.dart';
import '../features/consumer/seller_application/seller_application_form_screen.dart';
import '../features/shared/settings/edit_profile_screen.dart';

// Seller imports added below
import '../features/consumer/wishlist/wishlist_screen.dart';
import '../features/seller/listings/add_edit_listing_screen.dart';
import '../features/seller/dashboard/seller_dashboard_screen.dart';
import '../features/seller/listings/seller_listings_page.dart';
import '../features/seller/orders/seller_orders_screen.dart';
import '../features/seller/earnings/seller_earnings_screen.dart';
import '../features/seller/profile/seller_profile_screen.dart';
import '../features/shared/notifications/notifications_screen.dart';
import '../features/shared/orders/order_detail_screen.dart';
import '../features/shared/reviews/reviews_screen.dart';
import '../features/shared/settings/settings_screen.dart';
import '../shared/components/bottom_nav_bar.dart';
import '../features/admin/seller_applications/seller_applications_screen.dart';

export 'app_routes.dart';

GoRouter? _appRouter;

GoRouter get appRouter => _appRouter ??= GoRouter(
  initialLocation: AppRoutes.landing,
  refreshListenable: onboardingController,
  redirect: (_, state) => resolveRedirectPath(
    path: state.uri.path,
    onboardingController: onboardingController,
  ),
  routes: [
    GoRoute(path: AppRoutes.landing, builder: (_, __) => const SplashScreen()),
    GoRoute(path: AppRoutes.splash, redirect: (_, __) => AppRoutes.landing),
    GoRoute(
        path: AppRoutes.languageSelect,
        builder: (_, __) => const LanguageSelectScreen()),
    GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
    GoRoute(
        path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
    GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen()),
    GoRoute(
        path: AppRoutes.consumerSetup,
        builder: (_, __) => const ProfileSetupScreen()),
    ShellRoute(
        builder: (_, __, child) => _RoleShell(farmer: true, child: child),
        routes: [
          GoRoute(
              path: AppRoutes.farmerHome,
              builder: (_, __) => const FarmerHomeScreen()),
          GoRoute(
              path: '/farmer/listings',
              builder: (_, __) => const ListingsScreen()),
          GoRoute(
              path: '/farmer/orders',
              builder: (_, __) => const FarmerOrdersScreen()),
          GoRoute(
              path: '/farmer/earnings',
              builder: (_, __) => const EarningsScreen()),
          GoRoute(
              path: '/farmer/promotions',
              builder: (_, __) => const PromotionsScreen()),
        ]),
    ShellRoute(
        builder: (_, __, child) => _RoleShell(farmer: false, child: child),
        routes: [
          GoRoute(
              path: AppRoutes.consumerHome,
              builder: (_, __) => const ConsumerHomeScreen()),
          GoRoute(
              path: '/consumer/search',
              builder: (_, state) {
                final catString = state.uri.queryParameters['category'];
                final cat = catString != null ? ListingCategory.values.byName(catString) : null;
                return SearchScreen(initialCategory: cat);
              }),
          GoRoute(
              path: AppRoutes.wishlist,
              builder: (_, __) => const WishlistScreen()),
          GoRoute(path: AppRoutes.cart, builder: (_, __) => const CartScreen()),
          GoRoute(
              path: '/consumer/orders',
              builder: (_, __) => const OrderTrackingScreen()),
        ]),
    GoRoute(
        path: AppRoutes.product,
        builder: (_, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!)),
    GoRoute(
        path: '/farmer/listings/add',
        builder: (_, __) => const ListingFormScreen()),
    GoRoute(
        path: '/farmer/listings/add/photo',
        redirect: (_, __) => '/farmer/listings/add'),
    GoRoute(
        path: '/farmer/listings/add/details',
        redirect: (_, __) => '/farmer/listings/add'),
    GoRoute(
        path: '/farmer/listings/add/price',
        redirect: (_, __) => '/farmer/listings/add'),
    GoRoute(
        path: '/farmer/listings/:id/edit',
        builder: (_, state) =>
            ListingFormScreen(listingId: state.pathParameters['id']!)),
    GoRoute(
        path: '/farmer/orders/:id',
        builder: (_, state) => OrderDetailScreen(
            orderId: state.pathParameters['id']!, farmerView: true)),
    GoRoute(
        path: '/consumer/farmer/:id',
        builder: (_, state) => FarmerProfileScreen(farmerId: state.pathParameters['id']!)),
    GoRoute(path: AppRoutes.checkout, builder: (_, __) => const CheckoutScreen()),
    GoRoute(path: AppRoutes.orderConfirmation, builder: (_, __) => const OrderConfirmationScreen()),
    GoRoute(
        path: '${AppRoutes.consumerOrders}/:id',
        builder: (_, state) => OrderDetailScreen(
            orderId: state.pathParameters['id']!, farmerView: false)),
    GoRoute(
        path: '/consumer/orders/:id/review',
        builder: (_, state) => ReviewsScreen(orderId: state.pathParameters['id']!)),
    GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: AppRoutes.sellerApply, builder: (_, __) => const SellerApplicationFormScreen()),
    GoRoute(path: AppRoutes.editProfile, builder: (_, __) => const EditProfileScreen()),
    GoRoute(path: AppRoutes.sellerDashboard, builder: (_, __) => const SellerDashboardScreen()),
    GoRoute(path: AppRoutes.sellerListings, builder: (_, __) => const SellerListingsPage()),
    GoRoute(path: AppRoutes.sellerListingsCreate, builder: (_, __) => const AddEditListingScreen()),
    GoRoute(path: AppRoutes.sellerListingsEdit, builder: (context, state) => AddEditListingScreen(listingId: state.pathParameters['id']!)),
    GoRoute(path: AppRoutes.sellerOrders, builder: (_, __) => const SellerOrdersScreen()),
    GoRoute(path: AppRoutes.sellerEarnings, builder: (_, __) => const SellerEarningsScreen()),
    GoRoute(path: AppRoutes.sellerProfile, builder: (_, __) => const SellerProfileScreen()),
    GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (_, __) => const AdminDashboardScreen()),
    // Seller applications management screen for admins
    GoRoute(
        path: AppRoutes.adminSellerApplications,
        builder: (_, __) => const SellerApplicationsScreen()),
  ],
);

class _RoleShell extends StatelessWidget {
  const _RoleShell({required this.farmer, required this.child});
  final bool farmer;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final destinations = farmer
        ? const [
            '/farmer/home',
            '/farmer/listings',
            '/farmer/orders',
            '/farmer/earnings',
            '/settings'
          ]
        : const [
            '/consumer/home',
            '/consumer/search',
            '/consumer/wishlist',
            '/consumer/cart',
            '/consumer/orders',
            '/settings'
          ];
    final currentPath = GoRouterState.of(context).uri.path;
    final index = destinations
        .indexOf(currentPath)
        .clamp(0, destinations.length - 1)
        .toInt();
    return Scaffold(
        body: child,
        bottomNavigationBar: AppBottomNavBar(
            farmer: farmer,
            index: index,
            onChanged: (next) => context.go(destinations[next])));
  }
}
