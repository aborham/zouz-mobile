import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:zouz_mobile/core/utils/image_utils.dart';
import 'package:zouz_mobile/features/scanner/providers/menu_provider.dart';
import 'package:zouz_mobile/features/cart/providers/cart_provider.dart';
import 'package:zouz_mobile/features/cart/providers/cart_provider.dart' as cart_models;

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
      ref.read(menuNotifierProvider.notifier).fetchMenu(widget.tenantSlug, widget.standId);
    });
  }

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
    final cartState = ref.watch(cartProvider);
    final locale = context.locale.languageCode;

    if (menuState.isLoading && menuState.tenant == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final tenant = menuState.tenant;
    final packages = menuState.packages ?? [];
    
    if (tenant == null) {
      return Scaffold(body: Center(child: Text('scanner.tenant_not_found'.tr())));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildModernHeader(tenant, locale),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildPackageCard(packages[index], tenant, locale),
                    childCount: packages.length,
                  ),
                ),
              ),
            ],
          ),
          if (cartState.totalItems > 0)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: _buildBottomCartBar(context, cartState),
            ),
        ],
      ),
    );
  }

  Widget _buildModernHeader(Map<String, dynamic> tenant, String locale) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: const Color(0xFF6B4226), // Coffee brown fallback
      automaticallyImplyLeading: false,
      actions: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            child: IconButton(
              icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            if (tenant['coverImageUrl'] != null)
              Image.network(
                ImageUtils.getFullUrl(tenant['coverImageUrl'])!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF6B4226)),
              )
            else
              Container(color: const Color(0xFF6B4226)),
            
            // Subtle Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),

            // Shop Name and Rating (Centered in design)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    _getLocalizedValue(tenant['name'], locale),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Color(0xFF224AFB), size: 16),
                        SizedBox(width: 4),
                        Text(
                          "4.5",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Circular Logo Overlap
            Positioned(
              bottom: -45,
              right: 30,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: ClipOval(
                  child: tenant['logoUrl'] != null
                      ? Image.network(
                          ImageUtils.getFullUrl(tenant['logoUrl'])!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
                        )
                      : Container(color: Colors.grey[200], child: const Icon(Icons.store)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> pkg, Map<String, dynamic> tenant, String locale) {
    final cart = ref.watch(cartProvider);
    final cartItemIndex = cart.items.indexWhere((i) => i.packageId == pkg['id']);
    final isInCart = cartItemIndex >= 0;
    final quantity = isInCart ? cart.items[cartItemIndex].quantity : 0;

    return InkWell(
      onTap: () {
        // Pass both package and tenant information if needed, or just package
        context.push('/package', extra: pkg);
      },
      borderRadius: BorderRadius.circular(28),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getLocalizedValue(pkg['name'], locale),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getLocalizedValue(pkg['description'], locale),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Action Button on the LEFT
                        if (!isInCart)
                          InkWell(
                            onTap: () => _addToCart(pkg, tenant, locale),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF224AFB),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF224AFB).withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'cart.add_to_cart'.tr(),
                                    style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.add, size: 18, color: Colors.white),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EDFF),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(10),
                                  icon: const Icon(Icons.remove, size: 20, color: Color(0xFF224AFB)),
                                  onPressed: () => ref.read(cartProvider.notifier).updateQuantity(pkg['id'], quantity - 1),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    '$quantity',
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.black),
                                  ),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(10),
                                  icon: const Icon(Icons.add, size: 20, color: Color(0xFF224AFB)),
                                  onPressed: () => ref.read(cartProvider.notifier).updateQuantity(pkg['id'], quantity + 1),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        // Price on the RIGHT
                        Text(
                          '${pkg['price']} ${'dashboard.currency'.tr()}',
                          style: const TextStyle(
                            color: Color(0xFF224AFB),
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Circular-ish Image on the right
              Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Colors.grey[50],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: pkg['imageUrl'] != null
                      ? Image.network(
                          ImageUtils.getFullUrl(pkg['imageUrl'])!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.fastfood_outlined, color: Colors.grey),
                        )
                      : const Icon(Icons.fastfood_outlined, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addToCart(Map<String, dynamic> pkg, Map<String, dynamic> tenant, String locale) {
    ref.read(cartProvider.notifier).addItem(
          cart_models.CartItem(
            packageId: pkg['id'],
            packageName: _getLocalizedValue(pkg['name'], locale),
            price: double.tryParse(pkg['price']?.toString() ?? '0') ?? 0.0,
            quantity: 1,
            type: pkg['type'] ?? 'QUANTITY',
            tenantId: tenant['id'],
            standId: widget.standId,
            imageUrl: pkg['imageUrl'],
          ),
        );
  }

  Widget _buildBottomCartBar(BuildContext context, CartState cart) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2337),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/cart'),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${cart.totalPrice.toStringAsFixed(2)} ${'dashboard.currency'.tr()}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
            const Spacer(),
            Text(
              '${'cart.view_cart'.tr()} (${cart.totalItems} ${'cart.items_count'.tr().replaceAll('{}', '').trim()})',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }
}
