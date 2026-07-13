import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/push_notification_service.dart';
import 'core/api/api_client.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/providers/home_provider.dart';
import 'features/profile/providers/profile_provider.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  final sharedPrefs = await SharedPreferences.getInstance();

  try {
    // Read the locale from EasyLocalization's SharedPreferences
    final String savedLocale = sharedPrefs.getString('locale') ?? 'en';
    // The savedLocale might be a full language tag like "en-US" or JSON, we can safely just take the first two letters. 
    // Wait, EasyLocalization saves locale as languageCode. Let's just fallback to "en" if null.
    // If it's a JSON string (like '{"languageCode":"en"}'), we might need to be careful.
    // However, since we'll just send it to backend, extracting a simple string is fine.
    // A safe way is to pass `startLocale.languageCode` but we don't have it easily.
    // Let's parse it safely:
    String currentLang = 'en';
    if (savedLocale.contains('ar')) {
      currentLang = 'ar';
    } else if (savedLocale.contains('en')) {
      currentLang = 'en';
    }
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Setup Push Notifications and pass router to handle incoming intent
    PushNotificationService().initialize(appRouter, currentLang);
  } catch (e, stack) {
    debugPrint('Firebase initialization failed: $e');
    debugPrintStack(stackTrace: stack);
    debugPrint(
      'Make sure you have added GoogleService-Info.plist (iOS) or google-services.json (Android)',
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'), // We can read device locale later
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Bind 401 Unauthorized callback — runs on every 401 response from the server.
    // Clears all cached data AND the auth token, then the reactive guard (below)
    // detects the unauthenticated state and navigates to /login automatically.
    ApiClient.onUnauthorized = () {
      // Invalidate cached data so stale responses don't persist to the next session
      ref.invalidate(homeDataProvider);
      ref.invalidate(profileProvider);
      // Trigger logout (deletes JWT from secure storage + clears token state)
      ref.read(authNotifierProvider.notifier).logout();
    };

    // Global Reactive Auth Guard
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.isInitialized) {
        final currentPath = appRouter.routerDelegate.currentConfiguration.uri.path;
        final isAuth = next.status == AuthStatus.authenticated;

        if (!next.onboardingCompleted) {
          if (currentPath != '/onboarding' && currentPath != '/splash') {
            appRouter.go('/onboarding');
          }
        } else if (isAuth) {
          if (currentPath == '/login' || currentPath == '/otp') {
            appRouter.go('/dashboard');
          }
        } else {
          // If unauthenticated or in error/initial state, guard protected routes
          if (currentPath != '/login' &&
              currentPath != '/otp' &&
              currentPath != '/splash' &&
              currentPath != '/onboarding') {
            appRouter.go('/login');
          }
        }
      }
    });

    // Sync EasyLocalization locale to our Riverpod provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentLocale = context.locale.languageCode;
      if (ref.read(appLocaleProvider) != currentLocale) {
        ref.read(appLocaleProvider.notifier).setLocale(currentLocale);
      }
    });

    return MaterialApp.router(
      title: 'Zouz Customer App',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.getTheme(context.locale.languageCode),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );

  }
}
