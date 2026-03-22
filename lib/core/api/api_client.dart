import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zouz_mobile/core/config/app_config.dart';

class AppLocale extends Notifier<String> {
  @override
  String build() => 'en';

  void setLocale(String locale) => state = locale;
}

final appLocaleProvider = NotifierProvider<AppLocale, String>(AppLocale.new);

class AuthTokenNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void updateToken(String? value) => state = value;
}

final authTokenProvider = NotifierProvider<AuthTokenNotifier, String?>(AuthTokenNotifier.new);

class ApiClient {
  final Dio _dio;
  final Ref _ref;

  ApiClient(this._dio, this._ref) {
    _dio.options.baseUrl = '${AppConfig.customerApiBaseUrl}/';
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add language header
          final currentLocale = _ref.read(appLocaleProvider);
          options.headers['Accept-Language'] = currentLocale;
          options.headers['x-language'] = currentLocale;

          // Add auth header if token exists
          final token = _ref.read(authTokenProvider);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          return handler.next(options);
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(responseBody: true, requestBody: true),
    );
  }

  Dio get dio => _dio;

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}

final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio, ref);
});
