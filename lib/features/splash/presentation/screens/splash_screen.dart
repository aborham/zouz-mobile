import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/services/app_update_service.dart';
import '../../../common/presentation/widgets/app_update_dialog.dart';
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  bool _isCheckingUpdate = false;
  bool _updateChecked = false;
  bool _forceUpdateRequired = false;
  bool _isShowingUpdateDialog = false;

  Future<void> _handleNavigation(AuthState authState) async {
    if (!authState.isInitialized) return;
    if (_forceUpdateRequired) return;

    if (!_updateChecked) {
      if (_isCheckingUpdate) return;
      _isCheckingUpdate = true;

      final updateService = AppUpdateService();
      final updateInfo = await updateService.checkUpdate();
      
      _updateChecked = true;
      _isCheckingUpdate = false;

      if (!mounted) return;

      if (updateInfo != null && updateInfo.updateAvailable) {
        if (updateInfo.forceUpdate) {
          _isShowingUpdateDialog = true;
          debugPrint('SplashScreen: Showing Mandatory AppUpdateDialog');
          await AppUpdateDialog.show(context, updateInfo);
          _isShowingUpdateDialog = false;
          _forceUpdateRequired = true;
          return;
        } else {
          // It's optional: save it and show it on the Home Screen instead
          AppUpdateService.pendingOptionalUpdate = updateInfo;
        }
      }
    } else if (_isCheckingUpdate || _isShowingUpdateDialog) {
      return;
    }

    final latestState = ref.read(authNotifierProvider);
    if (!latestState.onboardingCompleted) {
      context.go('/onboarding');
    } else if (latestState.status == AuthStatus.authenticated) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.isInitialized) {
        _handleNavigation(next);
      }
    });

    // Check once in build in case it initialized before listener attached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(authNotifierProvider);
      if (state.isInitialized) {
        _handleNavigation(state);
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/zouz_gradiants1.png',
              fit: BoxFit.cover,
            ),
          ),
          // Content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/zouz_logo_white.png',
                    width: 400, // Adjust size as needed
                  ),
                  Transform.translate(
                    offset: const Offset(0, -160), // Pull the slogan up
                    child: Text(
                      'common.slogan'.tr(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Footer
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '© ${DateTime.now().year} Zouz App',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );


  }
}





