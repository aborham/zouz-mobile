import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:device_info_plus/device_info_plus.dart' as device_info_plus;
import 'package:package_info_plus/package_info_plus.dart' as package_info_plus;
import 'package:dio/dio.dart' as dio_lib;
import 'package:zouz_mobile/core/config/app_config.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description: 'This channel is used for important notifications.', // description
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
  await PushNotificationService._syncNotificationToBackend(message);
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();

  factory PushNotificationService() {
    return _instance;
  }

  PushNotificationService._internal();

  static Future<void> _syncNotificationToBackend(RemoteMessage message) async {
    try {
      // If the backend already saved it, it will pass backend_saved flag
      if (message.data['backend_saved'] == 'true') return;

      // Extract title and body
      final title = message.notification?.title ?? message.data['title'];
      final body = message.notification?.body ?? message.data['body'];

      if (title == null && body == null) return;

      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      if (token == null) return;

      final dio = dio_lib.Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';

      await dio.post(
        '${AppConfig.customerApiBaseUrl}/notifications/sync',
        data: {
          'title': title,
          'body': body,
          'data': message.data,
        },
      );
      debugPrint('Successfully synced FCM notification to backend');
    } catch (e) {
      debugPrint('Failed to sync notification: $e');
    }
  }

  Future<void> initialize(GoRouter router, String appLanguage) async {
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

    // To display notifications in the foreground on Apple devices:
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    );

    // Initialize flutter_local_notifications for Android & iOS
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings);

    if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    // Register Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get FCM Token
    try {
      String? token = await messaging.getToken();
      debugPrint("FCM Token: $token");
      
      // Get Firebase Installation ID for In-App Messaging testing
      try {
        String installationId = await FirebaseInstallations.instance.getId();
        debugPrint("Firebase Installation ID (for In-App Messaging): $installationId");
      } catch (e) {
        debugPrint("Failed to get Firebase Installation ID: $e");
      }

      if (token != null) {
        // Send device info to backend
        try {
          String? deviceType;
          String? deviceModel;
          String? osVersion;
          String? appVersion;

          final packageInfo = await package_info_plus.PackageInfo.fromPlatform();
          appVersion = packageInfo.version;

          final deviceInfo = device_info_plus.DeviceInfoPlugin();
          if (Platform.isIOS) {
            deviceType = 'IOS';
            final iosInfo = await deviceInfo.iosInfo;
            deviceModel = iosInfo.model;
            osVersion = iosInfo.systemVersion;
          } else if (Platform.isAndroid) {
            deviceType = 'ANDROID';
            final androidInfo = await deviceInfo.androidInfo;
            deviceModel = androidInfo.model;
            osVersion = androidInfo.version.release;
          }

          final dio = dio_lib.Dio();
          await dio.post(
            '${AppConfig.customerApiBaseUrl}/device',
            data: {
              'token': token,
              'type': deviceType,
              'model': deviceModel,
              'osVersion': osVersion,
              'appVersion': appVersion,
              'appLanguage': appLanguage,
            },
          );
          debugPrint("Device registered successfully");
        } catch (e) {
          debugPrint("Failed to register device: $e");
        }
      }
    } catch (e) {
      debugPrint("Failed to get FCM token: $e");
    }

    // Handle incoming messages while app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');
      PushNotificationService._syncNotificationToBackend(message);

      if (message.notification != null) {
        debugPrint(
          'Message also contained a notification: ${message.notification}',
        );

        final notification = message.notification!;
        final android = message.notification?.android;

        // Manually show the notification if the app is in the foreground
        // We only do this for Android because iOS handles it natively via
        // setForegroundNotificationPresentationOptions and AppDelegate's willPresent.
        if (Platform.isAndroid && android != null) {
          _flutterLocalNotificationsPlugin.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                icon: '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
          );
        }
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
