# Zouz Mobile — System Overview

> **READ THIS FIRST.** Every agent must read this document before starting any task on the mobile app.

---

## 1. Product Context

**Zouz Mobile** is the customer-facing Flutter app for the Zouz platform. Customers use it to:
- Scan QR stands at stores → browse menus → buy packages
- View their wallet (active packages)
- Show redemption QR code → cashier scans → deducts from balance
- Receive push notifications for purchases, low balance, promotions

The backend is the **package-platform** Next.js API at `/api/customer/` endpoints.

---

## 2. Tech Stack (Exact Versions)

| Layer | Technology | Version |
|-------|-----------|---------|
| Framework | **Flutter** | SDK `^3.9.2` |
| State Management | **Riverpod** (flutter_riverpod) | `3.2.1` |
| Code Generation | **riverpod_annotation** | `4.0.2` |
| Routing | **GoRouter** | `17.1.0` |
| HTTP Client | **Dio** | `5.9.1` |
| Localization | **easy_localization** | `3.0.8` |
| Payments | **go_sell_sdk_flutter** (Tap) | `2.4.29` |
| Push Notifications | **Firebase Messaging** | `16.1.1` |
| Secure Storage | **flutter_secure_storage** | `10.0.0` |
| QR Scanning | **mobile_scanner** | `7.2.0` |
| QR Generation | **qr_flutter** | `4.1.0` |
| SVG | **flutter_svg** | `2.2.3` |
| Permissions | **permission_handler** | `11.3.1` |
| Date/Number | **intl** | `0.20.2` |
| Build Runner | **build_runner** | `2.9.0` |
| Linting | **flutter_lints** | `5.0.0` |

---

## 3. Architecture

### 3.1 Folder Structure
```
lib/
├── main.dart                          # App entry (Firebase, Riverpod, EasyLocalization)
├── core/
│   ├── api/api_client.dart            # Dio singleton with auth & locale interceptors
│   ├── router/app_router.dart         # GoRouter (10 routes)
│   ├── theme/
│   │   ├── app_theme.dart             # Material 3 ThemeData (light only)
│   │   └── colors.dart                # AppColors constants
│   ├── services/
│   │   └── push_notification_service.dart  # FCM setup, deep linking
│   ├── utils/image_utils.dart         # Image utilities
│   └── widgets/zouz_logo.dart         # Reusable logo widget
└── features/                          # Feature-first organization
    ├── auth/
    │   ├── presentation/screens/      # LoginScreen, OtpScreen
    │   ├── providers/auth_provider.dart
    │   └── repositories/auth_repository.dart
    ├── dashboard/
    │   ├── presentation/screens/      # MainNavigation, Home, Explore
    │   └── providers/navigation_provider.dart
    ├── scanner/
    │   ├── presentation/screens/      # QrScannerScreen, MenuScreen
    │   ├── providers/menu_provider.dart
    │   └── repositories/menu_repository.dart
    ├── packages/
    │   └── presentation/screens/      # PackageDetailScreen
    ├── checkout/
    │   └── presentation/screens/      # CheckoutScreen
    ├── purchases/
    │   ├── presentation/screens/      # PurchaseDetailScreen
    │   └── repositories/
    ├── profile/
    │   ├── models/profile_model.dart
    │   ├── presentation/screens/      # ProfileScreen, SettingsScreen
    │   ├── providers/profile_provider.dart
    │   └── repositories/profile_repository.dart
    ├── marketplace/
    │   └── presentation/screens/
    └── splash/
        └── presentation/screens/      # SplashScreen
```

### 3.2 Feature Module Structure
```
features/{feature_name}/
├── models/              # Data classes with fromJson/toJson
├── presentation/
│   ├── screens/         # Full-page widgets (StatelessWidget/ConsumerWidget)
│   └── widgets/         # Feature-specific reusable widgets
├── providers/           # Riverpod Notifier/NotifierProvider
└── repositories/        # API calls via Dio through ApiClient
```

---

## 4. Established Patterns

### 4.1 State Management (Riverpod)
```dart
// Provider pattern used in the project:
class AuthNotifier extends Notifier<AuthState> {
  late AuthRepository _repository;
  late ApiClient _apiClient;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    _apiClient = ref.watch(apiClientProvider);
    return AuthState();
  }
  // ... methods that modify state
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
```

### 4.2 Repository Pattern
```dart
class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<void> requestOtp(String phoneNumber) async {
    try {
      await _apiClient.dio.post('/auth/request-otp', data: {...});
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Fallback message');
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});
```

### 4.3 Model Pattern
```dart
class UserProfile {
  final String id;
  final String? name;
  // ...

  UserProfile({required this.id, this.name});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
    );
  }
}
```

### 4.4 Authentication Flow
1. User enters phone → `AuthNotifier.requestOtp()` → API sends OTP
2. User enters OTP → `AuthNotifier.verifyOtp()` → receives JWT
3. JWT stored in `flutter_secure_storage` (key: `jwt_token`)
4. JWT applied to all Dio requests via `ApiClient.setAuthToken()`

### 4.5 API Client
- Base URL: `/api/customer/` (relative to backend)
- Interceptors auto-attach `Accept-Language` and `x-language` headers
- Timeout: 10s connect, 10s receive

### 4.6 Navigation
- GoRouter with 10 routes
- Initial location: `/splash`
- Deep linking from push notifications to `/menu/{tenantSlug}`

### 4.7 Theme
- Material 3 with `AppColors` constants
- Primary: `#224AFB` (Blue), Secondary: `#6CF8FC` (Cyan)
- Light theme only (currently)
- Stadium-shaped buttons and inputs

---

## 5. Design Tokens (AppColors)

| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#224AFB` | Buttons, links, focus rings |
| `secondary` | `#6CF8FC` | Accents, brand highlights |
| `accent` | `#6CF8FC` | Same as secondary |
| `background` | `#FFFFFF` | Scaffold background |
| `surface` | `#F9FAFB` | Input fills, cards |
| `textPrimary` | `#231F20` | Main text |
| `textSecondary` | `#6B7280` | Hints, labels |
| `error` | `#EF4444` | Error states |
| `success` | `#22C55E` | Success indicators |
| `warning` | `#F59E0B` | Warning indicators |

---

## 6. API Endpoints Consumed

All endpoints are relative to the base URL (`/api/customer/`):
- `POST /auth/request-otp` — Send OTP
- `POST /auth/verify-otp` — Verify OTP, receive JWT
- `GET /profile` — Fetch user profile
- `PUT /profile` — Update profile
- `GET /menu/{tenantSlug}` — Fetch store menu/packages
- (More endpoints as features are developed)

---

## 7. Quick Reference Commands

```bash
# Run app
flutter run

# Analyze
flutter analyze

# Test
flutter test

# Build Android
flutter build apk --debug

# Build iOS
flutter build ios --no-codesign

# Run build_runner (for riverpod_annotation code gen)
dart run build_runner build --delete-conflicting-outputs

# Clean
flutter clean && flutter pub get
```
