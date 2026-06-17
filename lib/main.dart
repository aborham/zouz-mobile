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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  final sharedPrefs = await SharedPreferences.getInstance();

  try {
    await Firebase.initializeApp();
    // Setup Push Notifications and pass router to handle incoming intent
    PushNotificationService().initialize(appRouter);
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
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
    // Bind 401 Unauthorized callback
    ApiClient.onUnauthorized = (Ref ref) {
      ref.read(authNotifierProvider.notifier).logout();
      appRouter.go('/login');
    };

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
