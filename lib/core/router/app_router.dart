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
import '../services/analytics_service.dart';

// Placeholder for screens until implemented

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  observers: [AnalyticsService.instance.observer],
  routes: [
    GoRoute(
      name: 'splash',
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      name: 'login',
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      name: 'otp',
      path: '/otp',
      builder: (context, state) => const OtpScreen(),
    ),
    GoRoute(
      path: '/complete-profile',
      name: 'complete-profile',
      builder: (context, state) => const CompleteProfileScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const MainNavigationScreen(),
    ),
    GoRoute(
      path: '/scanner',
      name: 'scanner',
      builder: (context, state) => const QrScannerScreen(),
    ),
    GoRoute(
      path: '/menu/:tenantSlug',
      name: 'menu',
      builder: (context, state) {
        final tenantSlug = state.pathParameters['tenantSlug']!;
        final standId =
            state.uri.queryParameters['standId'] ??
            state.uri.queryParameters['stand'];
        return MenuScreen(tenantSlug: tenantSlug, standId: standId);
      },
    ),
    GoRoute(
      path: '/scan/:tenantSlug',
      name: 'scan-menu',
      builder: (context, state) {
        final tenantSlug = state.pathParameters['tenantSlug']!;
        final standId =
            state.uri.queryParameters['standId'] ??
            state.uri.queryParameters['stand'];
        // Reusing MenuScreen for scan results
        return MenuScreen(tenantSlug: tenantSlug, standId: standId);
      },
    ),
    GoRoute(
      path: '/package',
      name: 'package-detail',
      builder: (context, state) {
        final package = state.extra as Map<String, dynamic>;
        return PackageDetailScreen(package: package);
      },
    ),
    GoRoute(
      name: 'cart',
      path: '/cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/checkout',
      name: 'checkout',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return CheckoutScreen(
          package: extra['package'],
          items: extra['items'] != null
              ? List<Map<String, dynamic>>.from(extra['items'])
              : null,
          fromCart: extra['fromCart'] ?? false,
        );
      },
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const AccountScreen(),
    ),
    GoRoute(
      path: '/profile/personal-info',
      name: 'personal-info',
      builder: (context, state) => const PersonalInfoScreen(),
    ),
    GoRoute(
      path: '/profile/payment-methods',
      name: 'payment-methods',
      builder: (context, state) => const PaymentMethodsScreen(),
    ),
    GoRoute(
      path: '/profile/support',
      name: 'support',
      builder: (context, state) => const SupportScreen(),
    ),
    GoRoute(
      path: '/profile/notifications',
      name: 'notification-settings',
      builder: (context, state) => const NotificationsSettingsScreen(),
    ),
    GoRoute(
      path: '/profile/notifications-list',
      name: 'notifications',
      builder: (context, state) => const NotificationsListScreen(),
    ),

    GoRoute(
      path: '/profile/language',
      name: 'language',
      builder: (context, state) => const LanguageScreen(),
    ),
    GoRoute(
      path: '/profile/legal/:type',
      name: 'legal-document',
      builder: (context, state) =>
          LegalDocsScreen(type: state.pathParameters['type'] ?? 'terms'),
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
      name: 'purchases',
      builder: (context, state) => PurchasesScreen(
        historyMode: state.uri.queryParameters['view'] == 'history',
      ),
    ),
    GoRoute(
      path: '/purchase-details',
      name: 'purchase-details',
      builder: (context, state) {
        final package = state.extra as Map<String, dynamic>;
        return PurchaseDetailScreen(package: package);
      },
    ),
  ],
);
