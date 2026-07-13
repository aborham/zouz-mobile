import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();

  factory PushNotificationService() {
    return _instance;
  }

  PushNotificationService._internal();

  Future<void> initialize(GoRouter router) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // Register Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get FCM Token
    try {
      String? token = await messaging.getToken();
      debugPrint("FCM Token: $token");
      // Token is sent to backend during OTP verification in AuthProvider
    } catch (e) {
      debugPrint("Failed to get FCM token: $e");
    }

    // Handle incoming messages while app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
          'Message also contained a notification: ${message.notification}',
        );
      }
    });

    // Handle navigation when app is opened from a terminated state
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage, router);
    }

    // Handle navigation when app is opened from the background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message, router);
    });
  }

  void _handleMessage(RemoteMessage message, GoRouter router) {
    if (message.data['type'] == 'package') {
      final tenantSlug = message.data['tenantSlug'];
      final standId = message.data['standId'];
      if (tenantSlug != null) {
        String path = '/menu/$tenantSlug';
        if (standId != null) {
          path += '?standId=$standId';
        }
        router.push(path);
      }
    } else if (message.data['type'] == 'checkout') {
      // Navigate to purchases
      router.go('/home');
    }
  }
}
