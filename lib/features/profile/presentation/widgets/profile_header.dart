import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/image_utils.dart';

class PremiumProfileHeader extends StatelessWidget {
  final String? name;
  final String? email;
  final String? avatarUrl;
  final VoidCallback? onEditImage;
  final bool showEditButton;

  const PremiumProfileHeader({
    super.key,
    this.name,
    this.email,
    this.avatarUrl,
    this.onEditImage,
    this.showEditButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // 1. Background Orbs
        Positioned(
          top: -100,
          right: -50,
          child: _buildOrb(AppColors.secondary.withValues(alpha: 0.15), 250),
        ),
        Positioned(
          top: 100,
          left: -80,
          child: _buildOrb(AppColors.primary.withValues(alpha: 0.1), 200),
        ),

        // 2. Content
        Padding(
          padding: EdgeInsets.only(
            top: statusBarHeight + 20,
            bottom: 40,
            left: 24,
            right: 24,
          ),
          child: Column(
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Hero(
                        tag: 'profile_avatar',
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: AppColors.surface,
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(ImageUtils.getFullUrl(avatarUrl)!)
                              : null,
                          child: avatarUrl == null
                              ? const Icon(
                                  Icons.person_rounded,
                                  size: 50,
                                  color: AppColors.textSecondary,
                                )
                              : null,
                        ),
                      ),
                    ),
                    if (showEditButton)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: onEditImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Identity
              Text(
                name ?? 'profile.customer_name'.tr(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  email ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
