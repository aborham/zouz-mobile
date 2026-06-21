import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/complete_profile_screen.dart';
import '../../features/dashboard/presentation/screens/main_navigation_screen.dart';
import '../../features/scanner/presentation/screens/qr_scanner_screen.dart';
import '../../features/scanner/presentation/screens/menu_screen.dart';
import '../../features/packages/presentation/screens/package_detail_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/profile/presentation/screens/account_screen.dart';
import '../../features/profile/presentation/screens/personal_info_screen.dart';
import '../../features/profile/presentation/screens/payment_methods_screen.dart';
import '../../features/profile/presentation/screens/support_screen.dart';
import '../../features/profile/presentation/screens/notifications_settings_screen.dart';
import '../../features/profile/presentation/screens/notifications_list_screen.dart';
import '../../features/profile/presentation/screens/language_screen.dart';
import '../../features/profile/presentation/screens/legal_docs_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/checkout/presentation/screens/payment_success_screen.dart';
import '../../features/checkout/presentation/screens/payment_failure_screen.dart';
import '../../features/purchases/presentation/screens/purchases_screen.dart';
import '../../features/purchases/presentation/screens/purchase_details_screen.dart';

import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';


// Placeholder for screens until implemented

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/otp', builder: (context, state) => const OtpScreen()),
    GoRoute(path: '/complete-profile', builder: (context, state) => const CompleteProfileScreen()),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const MainNavigationScreen(),
    ),
    GoRoute(
      path: '/scanner',
      builder: (context, state) => const QrScannerScreen(),
    ),
    GoRoute(
      path: '/menu/:tenantSlug',
      builder: (context, state) {
        final tenantSlug = state.pathParameters['tenantSlug']!;
        final standId = state.uri.queryParameters['standId'];
        return MenuScreen(tenantSlug: tenantSlug, standId: standId);
      },
    ),
    GoRoute(
      path: '/scan/:tenantSlug',
      builder: (context, state) {
        final tenantSlug = state.pathParameters['tenantSlug']!;
        final standId = state.uri.queryParameters['standId'];
        // Reusing MenuScreen for scan results
        return MenuScreen(tenantSlug: tenantSlug, standId: standId);
      },
    ),
    GoRoute(
      path: '/package',
      builder: (context, state) {
        final package = state.extra as Map<String, dynamic>;
        return PackageDetailScreen(package: package);
      },
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return CheckoutScreen(
          package: extra['package'],
          items: extra['items'] != null ? List<Map<String, dynamic>>.from(extra['items']) : null,
          fromCart: extra['fromCart'] ?? false,
        );
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const AccountScreen(),
    ),
    GoRoute(
      path: '/profile/personal-info',
      builder: (context, state) => const PersonalInfoScreen(),
    ),
    GoRoute(
      path: '/profile/payment-methods',
      builder: (context, state) => const PaymentMethodsScreen(),
    ),
    GoRoute(
      path: '/profile/support',
      builder: (context, state) => const SupportScreen(),
    ),
    GoRoute(
      path: '/profile/notifications',
      builder: (context, state) => const NotificationsSettingsScreen(),
    ),
    GoRoute(
      path: '/profile/notifications-list',
      builder: (context, state) => const NotificationsListScreen(),
    ),

    GoRoute(
      path: '/profile/language',
      builder: (context, state) => const LanguageScreen(),
    ),
    GoRoute(
      path: '/profile/legal/:type',
      builder: (context, state) => LegalDocsScreen(
        type: state.pathParameters['type'] ?? 'terms',
      ),
    ),
    GoRoute(
      path: '/payment-success',
      name: 'payment-success',
      builder: (context, state) {
        final orderId = state.uri.queryParameters['orderId']!;
        return PaymentSuccessScreen(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/payment-failure',
      name: 'payment-failure',
      builder: (context, state) {
        final reason = state.uri.queryParameters['reason'];
        final extra = state.extra as Map<String, dynamic>?;
        return PaymentFailureScreen(
          reason: reason,
          package: extra?['package'],
          items: extra?['items'],
        );
      },
    ),
    GoRoute(
      path: '/purchases',
      builder: (context, state) => const PurchasesScreen(),
    ),
    GoRoute(
      path: '/purchase-details',
      builder: (context, state) {
        final package = state.extra as Map<String, dynamic>;
        return PurchaseDetailScreen(package: package);
      },
    ),
  ],
);
