import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/dashboard/presentation/screens/main_navigation_screen.dart';
import '../../features/scanner/presentation/screens/qr_scanner_screen.dart';
import '../../features/scanner/presentation/screens/menu_screen.dart';
import '../../features/packages/presentation/screens/package_detail_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/purchases/presentation/screens/purchase_details_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';

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
    GoRoute(
      path: '/home',
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
      path: '/package',
      builder: (context, state) {
        final package = state.extra as Map<String, dynamic>;
        return PackageDetailScreen(package: package);
      },
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) {
        final package = state.extra as Map<String, dynamic>;
        return CheckoutScreen(package: package);
      },
    ),
    GoRoute(
      path: '/purchase-details',
      builder: (context, state) {
        final package = state.extra as Map<String, dynamic>;
        return PurchaseDetailScreen(package: package);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
