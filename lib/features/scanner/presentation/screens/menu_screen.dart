import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:zouz_mobile/core/utils/image_utils.dart';
import 'package:zouz_mobile/features/scanner/providers/menu_provider.dart';

class MenuScreen extends ConsumerStatefulWidget {
  final String tenantSlug;
  final String? standId;

  const MenuScreen({super.key, required this.tenantSlug, this.standId});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(menuNotifierProvider.notifier)
          .fetchMenu(widget.tenantSlug, widget.standId);
    });
  }

  // Parses localized json
  String _getLocalizedValue(dynamic field, String locale) {
    if (field == null) return '';
    if (field is String) return field;
    if (field is Map) {
      return field[locale] ?? field['en'] ?? '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuNotifierProvider);
    final locale = context.locale.languageCode;

    if (menuState.isLoading && menuState.tenant == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (menuState.errorMessage != null && menuState.tenant == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  menuState.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref
                        .read(menuNotifierProvider.notifier)
                        .fetchMenu(widget.tenantSlug, widget.standId);
                  },
                  child: Text('common.retry'.tr()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final tenant = menuState.tenant;
    final packages = menuState.packages ?? [];
    final stand = menuState.stand;

    if (tenant == null) {
      return Scaffold(
        body: Center(child: Text('scanner.tenant_not_found'.tr())),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _getLocalizedValue(tenant['name'], locale),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (tenant['coverImageUrl'] != null)
                    Image.network(
                      ImageUtils.getFullUrl(tenant['coverImageUrl'])!,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(color: AppColors.primary),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (stand != null)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
                color: AppColors.secondary.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getLocalizedValue(stand['name'], locale),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final pkg = packages[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  clipBehavior: Clip.antiAlias,
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () {
                      // Pass package object or ID
                      context.push('/package', extra: pkg);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (pkg['imageUrl'] != null)
                          Image.network(
                            ImageUtils.getFullUrl(pkg['imageUrl'])!,
                            height: 140,
                            fit: BoxFit.cover,
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _getLocalizedValue(pkg['name'], locale),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      pkg['price'] != null
                                          ? '${pkg['price']} ${'dashboard.currency'.tr()}'
                                          : 'packages.price_unset'.tr(),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getLocalizedValue(pkg['description'], locale),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: packages.length),
            ),
          ),
        ],
      ),
    );
  }
}
