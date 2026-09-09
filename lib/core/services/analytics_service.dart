import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Privacy-safe product analytics for the customer app.
///
/// Never pass names, phone numbers, email addresses, payment tokens, full URLs,
/// or other user-provided text to this service.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> initialize() async {
    await _safe(() => _analytics.setAnalyticsCollectionEnabled(true));
    await _safe(
      () => _analytics.setDefaultEventParameters({'app_surface': 'customer'}),
    );
  }

  Future<void> login({required bool success}) =>
      event(success ? 'login_completed' : 'login_failed', {'method': 'otp'});

  Future<void> otpRequested({required bool success}) => event(
    success ? 'otp_requested' : 'otp_request_failed',
    {'method': 'sms'},
  );

  Future<void> qrScanned({required bool valid}) =>
      event(valid ? 'qr_scan_valid' : 'qr_scan_invalid');

  Future<void> addToCart({
    required String itemType,
    required double value,
    required int quantity,
  }) => event('add_to_cart', {
    'item_type': itemType,
    'currency': 'SAR',
    'value': value,
    'quantity': quantity,
  });

  Future<void> checkoutStarted({
    required String paymentMethod,
    required double value,
  }) => event('begin_checkout', {
    'payment_method': paymentMethod,
    'currency': 'SAR',
    'value': value,
  });

  Future<void> paymentFinished({
    required String paymentMethod,
    required bool success,
    required double value,
  }) => event(success ? 'purchase_completed' : 'purchase_failed', {
    'payment_method': paymentMethod,
    'currency': 'SAR',
    'value': value,
  });

  Future<void> event(String name, [Map<String, Object>? parameters]) =>
      _safe(() => _analytics.logEvent(name: name, parameters: parameters));

  Future<void> _safe(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (error) {
      // Analytics must never block or break a customer journey.
      debugPrint('Analytics event skipped: $error');
    }
  }
}
