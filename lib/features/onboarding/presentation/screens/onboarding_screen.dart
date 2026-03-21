import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:zouz_mobile/core/theme/colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      titleAR: 'روتينك اليومي، صار أسهل',
      titleEN: 'Your Daily Favorites, Simplified',
      descKey: 'onboarding.discover_desc',
      icon: Icons.auto_awesome, // Placeholder for lifestyle icon
      iconColors: [Colorkit.red, Colorkit.blue, Colorkit.navy],
    ),
    OnboardingPageData(
      titleAR: '!امسح الـ ستاند',
      titleEN: 'Scan the Stand!',
      descKey: 'onboarding.save_desc',
      icon: Icons.qr_code_scanner, // Placeholder for QR scan icon
      iconColors: [Colorkit.blue],
    ),
    OnboardingPageData(
      titleAR: 'محفظتك الرقمية الموحدة',
      titleEN: 'Your Unified QR Wallet',
      descKey: 'onboarding.claim_desc',
      icon: Icons.account_balance_wallet, // Placeholder for wallet icon
      iconColors: [Colorkit.blue, Colorkit.purple],
    ),
  ];

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/login');
    }
  }

  void _onBack() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isArabic = context.locale.languageCode == 'ar';
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _onBack,
                    )
                  else
                    const SizedBox(width: 48),
                  
                  TextButton(
                    onPressed: () {
                      if (isArabic) {
                        context.setLocale(const Locale('en'));
                      } else {
                        context.setLocale(const Locale('ar'));
                      }
                    },
                    child: Text(
                      isArabic ? 'English' : 'العربية',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Centered Illustration Placeholder
                        Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.1),
                                blurRadius: 40,
                                spreadRadius: -5,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              page.icon,
                              size: 100,
                              color: page.iconColors.first,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 60),

                        // Arabic Title
                        Text(
                          page.titleAR,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // English Subtitle (Blue)
                        Text(
                          page.titleEN,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // Description
                        Text(
                          page.descKey.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Area
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dot Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildIndicator(index == _currentPage),
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            (_currentPage == _pages.length - 1
                                    ? 'onboarding.get_started'
                                    : 'onboarding.next')
                                .tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (_currentPage > 0 || _currentPage == _pages.length - 1)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.arrow_forward_ios, size: 16),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 4,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPageData {
  final String titleAR;
  final String titleEN;
  final String descKey;
  final IconData icon;
  final List<Color> iconColors;

  OnboardingPageData({
    required this.titleAR,
    required this.titleEN,
    required this.descKey,
    required this.icon,
    required this.iconColors,
  });
}

class Colorkit {
  static const Color blue = Color(0xFF244BF9);
  static const Color red = Color(0xFFEF4444);
  static const Color navy = Color(0xFF1E293B);
  static const Color purple = Color(0xFF8B5CF6);
}

