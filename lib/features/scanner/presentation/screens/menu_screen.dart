import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:zouz_mobile/core/utils/image_utils.dart';
import 'package:saudi_riyal_symbol/saudi_riyal_symbol.dart';
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
      backgroundColor: const Color(0xFFF7F7FA),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildModernHeader(tenant, locale),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
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
      expandedHeight: 260,
      pinned: true,
      backgroundColor: const Color(0xFF6B4226),
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
            // 1. Image & Overlay - pushed up by 45px
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 45,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (tenant['coverImageUrl'] != null)
                    Image.network(
                      ImageUtils.getFullUrl(tenant['coverImageUrl'])!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF6B4226)),
                    )
                  else
                    Container(color: const Color(0xFF6B4226)),
                  
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 55, // Lifted up to sit above the logo!
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Text(
                          _getLocalizedValue(tenant['name'], locale),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 16),
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
                ],
              ),
            ),
            
            // 2. Curved bottom matching scaffold background
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 45,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F7FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
              ),
            ),

            // 3. Logo straddling the boundary exactly, back in center
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: tenant['logoUrl'] != null
                        ? Image.network(
                            ImageUtils.getFullUrl(tenant['logoUrl'])!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[100],
                              child: const Icon(Icons.store_rounded, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: Colors.grey[100],
                            child: const Icon(Icons.store_rounded, color: Colors.grey),
                          ),
                  ),
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

    final price = double.tryParse(pkg['price']?.toString() ?? '0') ?? 0.0;
    final originalPrice = pkg['originalPrice'] != null
        ? double.tryParse(pkg['originalPrice'].toString())
        : null;
    final hasDiscount = originalPrice != null && originalPrice > price;

    return InkWell(
      onTap: () {
        context.push('/package', extra: pkg);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getLocalizedValue(pkg['name'], locale),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getLocalizedValue(pkg['description'], locale),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    _buildPriceRow(price, originalPrice, hasDiscount),
                    const SizedBox(height: 12),
                    if (!isInCart)
                      _buildAddToCartButton(() => _addToCart(pkg, tenant, locale))
                    else
                      _buildQuantityStepper(pkg['id'], quantity),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey[50],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
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

  Widget _buildPriceRow(double price, double? originalPrice, bool hasDiscount) {
    return Row(
      children: [
        SaudiCurrencySymbol(
          price: price,
          priceStyle: const TextStyle(
            color: Color(0xFF224AFB),
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
          symbolFontColor: const Color(0xFF224AFB),
          isOldPrice: false,
        ),
        if (hasDiscount) ...[
          const SizedBox(width: 8),
          SaudiCurrencySymbol(
            price: originalPrice!,
            priceStyle: TextStyle(
              color: Colors.grey[500]!,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            symbolFontColor: Colors.grey[500]!,
            isOldPrice: true,
          ),
        ],
      ],
    );
  }

  Widget _buildAddToCartButton(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF1FF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.add, size: 20, color: Color(0xFF224AFB)),
      ),
    );
  }

  Widget _buildQuantityStepper(String packageId, int quantity) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => ref.read(cartProvider.notifier).updateQuantity(packageId, quantity - 1),
            borderRadius: BorderRadius.circular(14),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.remove, size: 20, color: Color(0xFF224AFB)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$quantity',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
            ),
          ),
          InkWell(
            onTap: () => ref.read(cartProvider.notifier).updateQuantity(packageId, quantity + 1),
            borderRadius: BorderRadius.circular(14),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.add, size: 20, color: Color(0xFF224AFB)),
            ),
          ),
        ],
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

