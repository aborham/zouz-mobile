import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../../auth/providers/auth_provider.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:zouz_mobile/features/onboarding/data/onboarding_repository.dart';


class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {

  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _onNext(int totalPages) {
    if (_currentPage < totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      ref.read(authNotifierProvider.notifier).completeOnboarding();
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
    final slidesAsync = ref.watch(onboardingSlidesProvider);

    return slidesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('common.error'.tr()),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(onboardingSlidesProvider),
                child: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
      ),
      data: (slides) {
        if (slides.isEmpty) {
          // Fallback if no slides exist in backend
          return Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Skip to Login'),
              ),
            ),
          );
        }

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
                    itemCount: slides.length,
                    itemBuilder: (context, index) {
                      final slide = slides[index];
                      final locale = context.locale.languageCode;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Centered Illustration (Lottie or Icon)
                            Container(
                              width: 280,
                              height: 280,
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
                                child: slide.lottieUrl != null
                                    ? Lottie.network(
                                        slide.lottieUrl!,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) => 
                                          const Icon(Icons.error_outline, size: 80, color: Colors.red),
                                      )
                                    : const Icon(
                                        Icons.auto_awesome, 
                                        size: 100, 
                                        color: AppColors.primary,
                                      ),
                              ),
                            ),
                            
                            const SizedBox(height: 48),

                            // Title (Localized from API)
                            Text(
                              slide.title[locale] ?? slide.title['en'] ?? '',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Subtitle (Localized from API - Blue)
                            if (slide.subtitle['en'] != null || slide.subtitle['ar'] != null)
                              Text(
                                (slide.subtitle[locale] ?? slide.subtitle['en'] ?? '').toString(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),


                            const SizedBox(height: 16),

                            // Description (Localized from API)
                            if (slide.description['en'] != null || slide.description['ar'] != null)
                              Text(
                                (slide.description[locale] ?? slide.description['en'] ?? '').toString(),
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
                          slides.length,
                          (index) => _buildIndicator(index == _currentPage),
                        ),
                      ),
                      
                      const SizedBox(height: 32),

                      // Action Button
                      ElevatedButton(
                        onPressed: () => _onNext(slides.length),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              (_currentPage == slides.length - 1
                                      ? 'onboarding.get_started'
                                      : 'onboarding.next')
                                  .tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (_currentPage > 0 || _currentPage == slides.length - 1)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.arrow_forward_ios, size: 16),
                              ),
                          ],
                        ),
                      ),

                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

class Colorkit {
  static const Color blue = Color(0xFF244BF9);
  static const Color red = Color(0xFFEF4444);
  static const Color navy = Color(0xFF1E293B);
  static const Color purple = Color(0xFF8B5CF6);
}


