import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

class SplashScreen extends StatefulWidget {


  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
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

    // Navigate to home/login after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/onboarding'); // We start with login as per current flow
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/zouz_logo_black.png',
                    width: 400, // Adjust size as needed
                  ),
                  Transform.translate(
                    offset: const Offset(0, -160), // Pull the slogan up
                    child: Text(
                      'common.slogan'.tr(),
                      style: const TextStyle(
                        color: Color(0xFF1F2937), // Dark gray
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
                style: const TextStyle(
                  color: Colors.black26,
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





