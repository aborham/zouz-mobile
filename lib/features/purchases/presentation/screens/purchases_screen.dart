import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../repositories/purchases_repository.dart';

final purchasesFilterProvider = StateProvider.autoDispose.family<String, bool>(
  (ref, historyMode) => 'ALL',
);

final purchasesFutureProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final authState = ref.watch(authNotifierProvider);
      if (!authState.isInitialized ||
          authState.status != AuthStatus.authenticated) {
        return <Map<String, dynamic>>[];
      }

      final repository = ref.watch(purchasesRepositoryProvider);
      return await repository.fetchPurchases();
    });

class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key, this.historyMode = false});

  /// The middle navigation tab is for usable/current purchases. Account order
  /// history is the complete financial record and includes refunded orders.
  final bool historyMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasesAsync = ref.watch(purchasesFutureProvider);
    final selectedFilter = ref.watch(purchasesFilterProvider(historyMode));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        // Show the OS back arrow when pushed onto the stack.
        // When there is no back route (direct entry from tab), show a home icon.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
        title: Text(
          historyMode
              ? 'profile.order_history'.tr()
              : 'dashboard.purchases'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: purchasesAsync.when(
        data: (purchases) {
          final visiblePurchases = historyMode
              ? purchases
              : purchases.where((purchase) => purchase['status'] != 'REFUNDED');
          final sortedPurchases = [...visiblePurchases]
            ..sort(_comparePurchases);
          final filteredPurchases = sortedPurchases.where((p) {
            final status = p['status'] ?? 'UNKNOWN';
            if (selectedFilter == 'ALL') return true;
            return selectedFilter == status;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(purchasesFutureProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(24),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildFilterTabs(ref, selectedFilter, historyMode),
                const SizedBox(height: 24),
                if (filteredPurchases.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'purchases.empty'.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filteredPurchases.map(
                    (package) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildPurchaseCard(context, package),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error: ${err.toString()}'),
              TextButton(
                onPressed: () => ref.refresh(purchasesFutureProvider),
                child: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(
    WidgetRef ref,
    String selectedFilter,
    bool includeRefunded,
  ) {
    final filters = [
      {'id': 'ALL', 'label': 'purchases.filter_all'.tr()},
      {'id': 'ACTIVE', 'label': 'purchases.filter_active'.tr()},
      {'id': 'DEPLETED', 'label': 'purchases.filter_fully_used'.tr()},
      {'id': 'EXPIRED', 'label': 'purchases.filter_expired'.tr()},
      if (includeRefunded)
        {'id': 'REFUNDED', 'label': 'purchases.filter_refunded'.tr()},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () =>
                  ref
                          .read(
                            purchasesFilterProvider(includeRefunded).notifier,
                          )
                          .state =
                      filter['id']!,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  filter['label']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPurchaseCard(
    BuildContext context,
    Map<String, dynamic> package,
  ) {
    final status = package['status'] ?? 'UNKNOWN';
    final isExpired = status == 'EXPIRED';

    // Mapped properties based on design
    final title = package['businessName'] ?? 'Unknown Business';
    final subtitle = package['packageName'] ?? 'Unknown Package';
    final paidAmount = double.tryParse(package['price']?.toString() ?? '');
    final price = paidAmount == null
        ? '—'
        : paidAmount == paidAmount.roundToDouble()
        ? paidAmount.toStringAsFixed(0)
        : paidAmount.toStringAsFixed(2);
    final currency = package['currency']?.toString() ?? 'SAR';

    final businessNameLower = title.toLowerCase();
    Color iconBgColor = const Color(0xFFFFF3E0);
    Color iconColor = const Color(0xFFEF6C00);
    IconData icon = Icons.coffee;

    if (businessNameLower.contains('salon') ||
        businessNameLower.contains('beauty')) {
      iconBgColor = const Color(0xFFFCE4EC);
      iconColor = const Color(0xFFC2185B);
      icon = Icons.spa;
    } else if (businessNameLower.contains('restaurant') ||
        businessNameLower.contains('مطعم')) {
      iconBgColor = const Color(0xFFFFEBEE);
      iconColor = const Color(0xFFD32F2F);
      icon = Icons.restaurant;
    }

    // Determine status tag style
    Color tagBgColor;
    Color tagTextColor;
    String tagText;

    if (status == 'REFUNDED') {
      tagBgColor = const Color(0xFFE3F2FD); // Light blue
      tagTextColor = const Color(0xFF1976D2);
      tagText = 'purchases.filter_refunded'.tr();
    } else if (status == 'DEPLETED') {
      tagBgColor = const Color(0xFFF3E8FF);
      tagTextColor = const Color(0xFF7E22CE);
      tagText = 'purchases.filter_fully_used'.tr();
    } else if (isExpired) {
      tagBgColor = const Color(0xFFFFEBEE); // Light red
      tagTextColor = const Color(0xFFD32F2F);
      tagText = 'purchases.filter_expired'.tr();
    } else {
      tagBgColor = const Color(0xFFE8F5E9); // Light green
      tagTextColor = const Color(0xFF388E3C);
      tagText = 'purchases.filter_active'.tr();
    }

    return GestureDetector(
      onTap: () => context.push('/purchase-details', extra: package),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Row: Info and Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),

                // Titles
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      if (package['redemptionMode'] == 'ITEMIZED') ...[
                        const SizedBox(height: 6),
                        Text(
                          (package['itemBalances'] as List<dynamic>? ??
                                  const [])
                              .map((item) {
                                final total =
                                    (item['initialQuantity'] as num?)
                                        ?.toInt() ??
                                    0;
                                final remaining =
                                    (item['remainingQuantity'] as num?)
                                        ?.toInt() ??
                                    0;
                                final used = (total - remaining).clamp(
                                  0,
                                  total,
                                );
                                return '${item['name']}: $used/$total';
                              })
                              .join(' • '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      currency,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Bottom Row: Status and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status Tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tagBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: tagTextColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    tagText,
                    style: TextStyle(
                      color: tagTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Date
                Text(
                  _formatDate(package['purchaseDate']),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            // Extra info row for expired items (like 12 unredeemed meals)
            if (isExpired && _remainingUnits(package) > 0) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'purchases.expired_with_unused'.tr(
                      args: [_remainingUnits(package).toString()],
                    ),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.info, color: Colors.grey, size: 14),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return 'N/A';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return isoString.split('T').first;
    }
  }

  int _remainingUnits(Map<String, dynamic> package) {
    if (package['redemptionMode'] == 'ITEMIZED') {
      return (package['itemBalances'] as List<dynamic>? ?? const []).fold<int>(
        0,
        (total, item) =>
            total + ((item['remainingQuantity'] as num?)?.toInt() ?? 0),
      );
    }
    return (package['remainingQuantity'] as num?)?.toInt() ?? 0;
  }

  int _comparePurchases(
    Map<String, dynamic> first,
    Map<String, dynamic> second,
  ) {
    const priority = {
      'ACTIVE': 0,
      'PENDING_ACTIVATION': 0,
      'PENDING_PAYMENT': 0,
      'DEPLETED': 1,
      'EXPIRED': 2,
      'REFUNDED': 3,
    };
    final statusComparison = (priority[first['status']] ?? 4).compareTo(
      priority[second['status']] ?? 4,
    );
    if (statusComparison != 0) return statusComparison;

    if (first['status'] == 'ACTIVE') {
      final firstExpiry = DateTime.tryParse(
        first['expiresAt']?.toString() ?? '',
      );
      final secondExpiry = DateTime.tryParse(
        second['expiresAt']?.toString() ?? '',
      );
      if (firstExpiry != null && secondExpiry != null) {
        final expiryComparison = firstExpiry.compareTo(secondExpiry);
        if (expiryComparison != 0) return expiryComparison;
      } else if (firstExpiry != null) {
        return -1;
      } else if (secondExpiry != null) {
        return 1;
      }
    }

    final firstPurchase =
        DateTime.tryParse(first['purchaseDate']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final secondPurchase =
        DateTime.tryParse(second['purchaseDate']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return secondPurchase.compareTo(firstPurchase);
  }
}
