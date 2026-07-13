import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:zouz_mobile/core/utils/image_utils.dart';
import 'package:zouz_mobile/features/cart/providers/cart_provider.dart';
import 'package:zouz_mobile/features/scanner/providers/menu_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  String selectedPaymentMethod = 'apple_pay'; // Mock state for Apple Pay selected

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final locale = context.locale.languageCode;
    final menuState = ref.watch(menuNotifierProvider);
    final tenant = menuState.tenant;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'cart.title'.tr(), // Verbatim "سلتي"
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(cartProvider.notifier).clear();
                context.pop();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'cart.clear'.tr(), // Verbatim "مسح السلة"
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: cart.items.isEmpty
          ? _buildEmptyState(context)
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Shop Header/Section Header
                    if (tenant != null) _buildTenantHeader(tenant, locale, cart),
                    const SizedBox(height: 16),
                    // Item List
                    _buildCartItemList(cart, locale),
                    const SizedBox(height: 32),
                    // Summary Section
                    _buildSummarySection(cart),
                    const SizedBox(height: 120), // Space for bottom button
                  ],
                ),
              ),
            ),
      bottomSheet: cart.items.isEmpty ? null : _buildMainActionButton(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    const String emptyCartSvg = '''
<svg width="150" height="150" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path opacity="0.1" d="M5 9H19L20 21H4L5 9Z" fill="#224AFB"/>
  <path d="M16 11V7C16 4.79086 14.2091 3 12 3C9.79086 3 8 4.79086 8 7V11M5 9H19L20 21H4L5 9Z" stroke="#224AFB" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="12" cy="15" r="2" fill="#224AFB" opacity="0.5"/>
</svg>
''';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.string(emptyCartSvg, width: 120, height: 120),
          const SizedBox(height: 24),
          Text(
            'cart.empty_title'.tr(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'cart.empty_subtitle'.tr(),
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantHeader(Map<String, dynamic> tenant, String locale, CartState cart) {
    return Row(
      children: [
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getLocalizedValue(tenant['name'], locale),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'cart.items_count'.tr(args: [cart.totalItems.toString()]), // Verbatim "X عناصر"
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFFE8E0), // Peach-colored background
          ),
          child: Center(
            child: tenant['logoUrl'] != null
                ? CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(ImageUtils.getFullUrl(tenant['logoUrl'])!),
                    backgroundColor: Colors.transparent,
                  )
                : const Icon(Icons.coffee_maker, color: Color(0xFF6B4226)), // Coffee machine style icon
          ),
        ),
      ],
    );
  }

  Widget _buildCartItemList(CartState cart, String locale) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cart.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final item = cart.items[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Quantity Counter on the Left
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.packageId, item.quantity - 1),
                      icon: const Icon(Icons.remove, size: 18, color: Colors.black54),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.packageId, item.quantity + 1),
                      icon: const Icon(Icons.add, size: 18, color: Colors.black54),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Center Descriptive Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.packageName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.visible,
                    ),
                    if (item.packageDescription != null && item.packageDescription!.isNotEmpty)
                      Text(
                        item.packageDescription!,
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      '${item.price} ${'dashboard.currency'.tr()}',
                      style: const TextStyle(
                        color: Color(0xFF224AFB), // Blue price text
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Circular Icon Container on the Right
              Container(
                width: 55,
                height: 55,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFE8E0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(27.5),
                  child: item.imageUrl != null
                      ? Image.network(ImageUtils.getFullUrl(item.imageUrl)!, fit: BoxFit.cover)
                      : const Icon(Icons.local_cafe, color: Color(0xFF224AFB)), // Placeholder icon
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummarySection(CartState cart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'checkout.summary'.tr(), // Verbatim "ملخص الطلب"
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 20),
          _buildSummaryRow('cart.subtotal'.tr(), '${cart.totalPrice} ${'dashboard.currency'.tr()}'),
          const SizedBox(height: 12),
          Text(
            'cart.prices_include_vat'.tr(), // Verbatim "الأسعار تشمل ضريبة القيمة المضافة"
            style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'cart.total'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              Text(
                '${cart.totalPrice} ${'dashboard.currency'.tr()}',
                style: const TextStyle(
                  color: Color(0xFF224AFB),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }



  Widget _buildMainActionButton(BuildContext context) {
    final cart = ref.read(cartProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: () {
            context.push('/checkout', extra: {
              'fromCart': true,
              'items': cart.items.map((e) => e.toMap()).toList(),
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF224AFB),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'cart.checkout'.tr(), // Verbatim "متابعة للدفع"
                style: const TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _getLocalizedValue(dynamic field, String locale) {
    if (field == null) return '';
    if (field is String) return field;
    if (field is Map) {
      return field[locale] ?? field['en'] ?? '';
    }
    return '';
  }
}
