---
trigger: always_on
---

# Zouz Mobile Agent Rules — Flutter Development Guidelines

> **Mandatory Pre-Read**: Before starting ANY task, read `/zouz/zouz-mobile/SYSTEM.md` first.
> Also read `/zouz/SYSTEM.md` for overall platform context.

---

## Rule 0: Anti-Hallucination Protocol

### 0.1 — Always Use Context7 MCP
Before writing ANY code that uses a Flutter/Dart package API, you MUST:
1. Call `mcp_context7_resolve-library-id` to find the package.
2. Call `mcp_context7_query-docs` to get current documentation.
3. Verify the class/method/widget exists in the CURRENT version.

**Zero tolerance for:**
- Invented widget constructors or method signatures.
- Using deprecated APIs (check against Flutter 3.9+ and Dart 3.9+ deprecations).
- Guessing import paths — verify them.
- Using old Riverpod API (e.g., `StateNotifier` instead of `Notifier`).

### 0.2 — Version Lock (Do NOT Upgrade)
Always use the exact versions from `pubspec.yaml`:
- Flutter SDK `^3.9.2`
- flutter_riverpod `3.2.1`
- riverpod_annotation `4.0.2`
- go_router `17.1.0`
- dio `5.9.1`
- easy_localization `3.0.8`
- go_sell_sdk_flutter `2.4.29`
- firebase_messaging `16.1.1`
- flutter_secure_storage `10.0.0`
- mobile_scanner `7.2.0`
- qr_flutter `4.1.0`
- intl `0.20.2`
- permission_handler `11.3.1`

### 0.3 — No Assumptions
- If unsure about a widget API, SAY SO. Do not fabricate.
- If a file path is uncertain, search for it first (`find_by_name`, `grep_search`).
- If unsure about a backend API endpoint, check `package-platform/src/app/api/customer/`.

---

## Rule 1: Read Before Write

Before modifying any file or area of the codebase:
1. Read `zouz-mobile/SYSTEM.md` for mobile architecture context.
2. Read the target file(s) you plan to modify.
3. Read related files (imports, providers, repositories, models).
4. Check `assets/translations/en.json` and `assets/translations/ar.json` for existing keys.
5. Check `core/theme/colors.dart` and `core/theme/app_theme.dart` for design tokens.
6. Check the centralized task registry at `/zouz/.agent/TASKS.md` for current status.

---

## Rule 2: Multi-Agent Workflow (Git Worktree)

### 2.1 — Branch Strategy
Each agent MUST work in its own git worktree to prevent conflicts.

```bash
# Create a worktree for your task
cd /Users/ahmed/zouz/zouz-mobile
git worktree add ../worktrees/mobile-<task-slug> -b feature/mobile-<task-slug>

# When done, merge and clean
git checkout main
git merge feature/mobile-<task-slug>
git worktree remove ../worktrees/mobile-<task-slug>
git branch -d feature/mobile-<task-slug>
```

### 2.2 — Naming Convention
- Branch: `feature/mobile-<task-id>-<short-description>` (e.g., `feature/mobile-T05-dark-theme`)
- Worktree directory: `../worktrees/mobile-<task-slug>`

### 2.3 — Conflict Prevention
- Never modify `pubspec.yaml` simultaneously with another agent — coordinate via TASKS.md.
- Never modify `core/api/api_client.dart`, `core/router/app_router.dart`, or `main.dart` without checking TASKS.md first.
- Translation files (`assets/translations/*.json`) require claiming before editing.
- Shared core files require claiming in the task registry before editing.

---

## Rule 3: Centralized Task Registry

All agents must read and update `/zouz/.agent/TASKS.md` at the project root.

### Before Starting:
1. Read `.agent/TASKS.md` to see active tasks.
2. Check if your target files are claimed by another agent.
3. Register your task with status `IN_PROGRESS`.

### After Completing:
1. Update your task status to `DONE` in `.agent/TASKS.md`.
2. List all files you modified.
3. Include your DoD checklist.

---

## Rule 4: Framework Compliance

### 4.1 — Flutter / Dart Rules
| ✅ DO | ❌ DON'T |
|-------|---------|
| Use Material 3 (`useMaterial3: true`) | Use Material 2 widgets |
| Use `const` constructors where possible | Create unnecessary rebuilds |
| Use `StatelessWidget` or `ConsumerWidget` | Use `StatefulWidget` unless absolutely necessary |
| Handle all `DioException` in repositories | Let exceptions propagate unhandled |
| Use `debugPrint()` for logging | Use `print()` |
| Use `WidgetStateProperty` (Flutter 3.9+) | Use deprecated `MaterialStateProperty` |
| Use `withValues()` for opacity | Use deprecated `.withOpacity()` |

### 4.2 — Riverpod Rules
| ✅ DO | ❌ DON'T |
|-------|---------|
| Use `Notifier` + `NotifierProvider` | Use deprecated `StateNotifier` / `StateNotifierProvider` |
| Use `ref.watch()` in build methods | Use `ref.read()` in build (causes missed rebuilds) |
| Use `ref.read()` in callbacks/methods | Use `ref.watch()` in callbacks |
| Declare providers at file top-level | Declare providers inside classes or functions |
| Follow the existing Notifier pattern (see SYSTEM.md §4.1) | Invent new state patterns |

### 4.3 — GoRouter Rules
| ✅ DO | ❌ DON'T |
|-------|---------|
| Register routes in `core/router/app_router.dart` | Create ad-hoc `Navigator.push` calls |
| Use `context.go()` for full navigation | Mix `go()` and `push()` without reason |
| Use `context.push()` for stack navigation | Use `Navigator.of(context)` directly |
| Pass data via `state.extra` or `state.pathParameters` | Pass complex data through constructors only |

### 4.4 — Dio / API Rules
| ✅ DO | ❌ DON'T |
|-------|---------|
| Use `ApiClient` from `core/api/api_client.dart` | Create raw `Dio()` instances |
| Use relative paths (e.g., `profile`) | Hardcode base URLs in repositories |
| Catch `DioException` specifically | Catch generic `Exception` in API calls |
| Return typed models from repositories | Return raw `Map<String, dynamic>` to UI |
| Pass `ref.watch(apiClientProvider)` to repositories | Hardcode API client instance |

### 4.5 — Auth / Secure Storage Rules
- JWT token stored in `flutter_secure_storage` (key: `jwt_token`).
- Set via `ApiClient.setAuthToken()` after login.
- Clear via `ApiClient.clearAuthToken()` on logout.
- Never store tokens in `SharedPreferences` or plain text.
- Never expose JWT token in logs.

---

## Rule 5: Feature Module Structure

### 5.1 — Every new feature MUST follow this structure:
```
features/{feature_name}/
├── models/              # Data classes with fromJson/toJson
├── presentation/
│   ├── screens/         # Full-page ConsumerWidget screens
│   └── widgets/         # Feature-specific reusable widgets
├── providers/           # Riverpod Notifier + NotifierProvider
└── repositories/        # API calls via ApiClient.dio
```

### 5.2 — File Naming
| Type | Convention | Example |
|------|-----------|---------|
| Screen | `snake_case_screen.dart` | `login_screen.dart` |
| Widget | `snake_case_widget.dart` | `order_card_widget.dart` |
| Provider | `snake_case_provider.dart` | `auth_provider.dart` |
| Repository | `snake_case_repository.dart` | `auth_repository.dart` |
| Model | `snake_case_model.dart` | `profile_model.dart` |

### 5.3 — State Class Pattern
Every feature must define explicit states:
```dart
enum FeatureStatus { initial, loading, loaded, error }

class FeatureState {
  final FeatureStatus status;
  final String? errorMessage;
  final List<DataModel> data;

  FeatureState({
    this.status = FeatureStatus.initial,
    this.errorMessage,
    this.data = const [],
  });

  FeatureState copyWith({...});
}
```

---

## Rule 6: Localization (Must-Pass)

### 6.1 — All Text Must Be Localized
- **No hardcoded user-facing strings.** All text via `"key".tr()` or `tr("key")`.
- Translation files: `assets/translations/en.json` and `assets/translations/ar.json`.
- Use nested key structure: `"auth.login.title"`, `"dashboard.home.welcome"`.

### 6.2 — RTL Requirements
- Layout must flip correctly (paddings, margins, icons, chevrons).
- Use `TextDirection`-aware widgets and `Directionality`.
- Use `TextAlign.start` / `TextAlign.end` (NOT `TextAlign.left/right`).
- Use `EdgeInsetsDirectional` instead of `EdgeInsets` for start/end.
- Use `AlignmentDirectional` instead of `Alignment` when direction matters.
- Numbers, phone numbers, and codes stay LTR even in RTL context.

### 6.3 — Date/Number Formatting
- Use `intl` package for date/number formatting per locale.
- Currency always SAR formatted per locale conventions.

### 6.4 — Deliverable
For every task, provide:
```
## Translation Keys Added/Updated
| Key | English | Arabic |
|-----|---------|--------|
| dashboard.home.title | "Home" | "الرئيسية" |
```

---

## Rule 7: Styling & Design System (Must-Pass)

### 7.1 — Color Usage
- All colors MUST come from `AppColors` in `core/theme/colors.dart`.
- Primary: `AppColors.primary` (`#224AFB`)
- Secondary: `AppColors.secondary` (`#6CF8FC`)
- Never hardcode hex colors in widgets.

### 7.2 — Theme Usage
- Use `Theme.of(context)` to access theme properties.
- Use `Theme.of(context).colorScheme.*` for semantic colors.
- Use `Theme.of(context).textTheme.*` for text styles.
- Never directly reference `Colors.*` when a theme token exists.

### 7.3 — Spacing & Sizing
- Use consistent spacing: 4, 8, 12, 16, 20, 24, 32, 48.
- Use `SizedBox` for fixed spacing, not `Padding` with only one side.
- Button minimum size: `56` height (matching theme).

### 7.4 — Deliverable
Confirm in your output:
```
## Theme Verification
- [x] Uses AppColors (no hardcoded colors)
- [x] Uses Theme.of(context) for text styles
- [x] Consistent spacing
- [x] RTL verified (EdgeInsetsDirectional, TextAlign.start/end)
```

---

## Rule 8: Data States (Must-Pass)

Every screen/widget that fetches data MUST handle ALL states:
1. **Loading** — `CircularProgressIndicator` or skeleton with localized text.
2. **Empty** — Localized message + optional CTA (e.g., "Scan a QR code to get started").
3. **Error** — Localized error message + retry button.
4. **Success** — Display data correctly.

### Pattern:
```dart
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(featureProvider);

  return switch (state.status) {
    FeatureStatus.loading => const Center(child: CircularProgressIndicator()),
    FeatureStatus.error => ErrorWidget(
        message: state.errorMessage ?? "error.generic".tr(),
        onRetry: () => ref.read(featureProvider.notifier).load(),
      ),
    FeatureStatus.loaded when state.data.isEmpty => EmptyStateWidget(...),
    FeatureStatus.loaded => DataListWidget(data: state.data),
    _ => const SizedBox.shrink(),
  };
}
```

No exceptions.

---

## Rule 9: Testing (Must-Pass)

### 9.1 — Before Marking Done
Every feature must pass:

```bash
# 1. Static analysis (zero warnings/errors)
flutter analyze

# 2. Unit/widget tests
flutter test

# 3. Build verification (catches compilation errors)
flutter build apk --debug

# 4. iOS build (if applicable)
flutter build ios --no-codesign
```

### 9.2 — Test Checklist
For every task output:
```
## Action Test Notes
- [ ] Feature works on Android emulator
- [ ] Feature works on iOS simulator (if applicable)
- [ ] Loading state renders
- [ ] Empty state renders
- [ ] Error state renders (tested with bad data / no network)
- [ ] Form validation works (if applicable)
- [ ] Navigation works (back, push, go)
- [ ] Auth guard works (if route is protected)
- [ ] `flutter analyze` passes ✅
- [ ] `flutter build apk --debug` passes ✅
```

---

## Rule 10: Navigation Conventions

### 10.1 — All Routes in `app_router.dart`
Never use `Navigator.push()` directly. All navigation via GoRouter.

### 10.2 — Route Registration Template
```dart
GoRoute(
  path: '/new-feature',
  builder: (context, state) {
    final data = state.extra as Map<String, dynamic>?;
    return NewFeatureScreen(data: data);
  },
),
```

### 10.3 — Deep Links
Push notification deep links handled in `PushNotificationService._handleMessage()`.
When adding a new deep link type:
1. Add the route in `app_router.dart`.
2. Add the handler case in `_handleMessage()`.

---

## Rule 11: Definition of Done (DoD)

**Every task MUST include this checklist before being marked as done:**

```markdown
## Definition of Done — Mobile

### Code Quality
- [ ] Follows feature module structure (models/presentation/providers/repositories)
- [ ] Uses existing patterns (Notifier, ApiClient, GoRouter)
- [ ] No `StatefulWidget` unless justified
- [ ] `const` constructors used where possible
- [ ] No deprecated APIs (MaterialStateProperty, withOpacity, etc.)

### Localization
- [ ] All text uses `.tr()` (no hardcoded strings)
- [ ] Keys added to both en.json and ar.json
- [ ] RTL verified (EdgeInsetsDirectional, TextAlign.start/end)
- [ ] Numbers/dates formatted per locale

### Data States
- [ ] Loading state implemented
- [ ] Empty state implemented
- [ ] Error state with retry implemented
- [ ] Success state implemented

### Styling
- [ ] Uses AppColors (no hardcoded colors)
- [ ] Uses Theme.of(context) for text styles
- [ ] Consistent spacing (4, 8, 12, 16, 20, 24, 32, 48)

### Testing
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] `flutter build apk --debug` passes
- [ ] Manual test steps documented

### Multi-Agent
- [ ] TASKS.md updated with completion status
- [ ] No conflicting file edits
- [ ] Branch ready for merge
```

---

## Rule 12: Red Flags (Stop and Fix Immediately)

🚫 Any hardcoded user-facing text (not using `.tr()`).
🚫 Any `TextAlign.left` or `TextAlign.right` (use `.start`/`.end`).
🚫 Any `EdgeInsets` with start/end semantics (use `EdgeInsetsDirectional`).
🚫 Any hardcoded color not from `AppColors`.
🚫 Any `new Dio()` outside of `api_client.dart`.
🚫 Any `Navigator.push()` instead of GoRouter.
🚫 Any `StateNotifier` or `StateNotifierProvider` (deprecated Riverpod).
🚫 Any `MaterialStateProperty` (deprecated in Flutter 3.9+).
🚫 Any `.withOpacity()` (use `.withValues(alpha:)`).
🚫 Any missing loading/empty/error state.
🚫 Any `print()` instead of `debugPrint()`.
🚫 Any JWT token logged or stored insecurely.
🚫 Any modification to shared files without checking TASKS.md.
🚫 Any `flutter analyze` warnings left unresolved.

---

## Rule 13: Git Commit Convention

```
<type>(mobile): <description>

# Types: feat, fix, refactor, style, docs, test, chore

# Examples:
feat(mobile): add package purchase flow
fix(mobile): resolve QR scanner rotation on Android
refactor(mobile): extract order card to reusable widget
```

---

## Rule 14: Platform API Contract

The mobile app consumes the platform backend at `/api/customer/`.

### 14.1 — Before Calling an API
1. Check that the endpoint exists in `package-platform/src/app/api/customer/`.
2. Verify request/response shape matches the backend implementation.
3. Never invent API endpoints that don't exist.

### 14.2 — Error Handling
```dart
try {
  final response = await _apiClient.dio.get('endpoint');
  return Model.fromJson(response.data);
} on DioException catch (e) {
  if (e.response?.statusCode == 401) {
    // Token expired — trigger re-auth
  }
  throw Exception(e.response?.data['error'] ?? 'Fallback message'.tr());
}
```

### 14.3 — Localized API Requests
The `ApiClient` interceptor automatically sends:
- `Accept-Language: ar|en`
- `x-language: ar|en`

Backend returns localized JSON fields based on these headers.
