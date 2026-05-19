import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import '../../repositories/purchases_repository.dart';
import '../widgets/purchase_summary_cards.dart';

final purchasesFilterProvider = StateProvider.autoDispose<String>((ref) => 'ALL');

final purchasesFutureProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final repository = ref.watch(purchasesRepositoryProvider);
      return await repository.fetchPurchases();
    });

class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasesAsync = ref.watch(purchasesFutureProvider);
    final selectedFilter = ref.watch(purchasesFilterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Slight off-white background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        title: Text(
          'dashboard.purchases'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: purchasesAsync.when(
        data: (purchases) {
          // Filter logic
          final filteredPurchases = purchases.where((p) {
            final status = p['status'] ?? 'UNKNOWN';
            if (selectedFilter == 'ALL') return true;
            if (selectedFilter == 'COMPLETED' && status == 'ACTIVE') return true; // Treating ACTIVE as COMPLETED in the UI for now
            if (selectedFilter == 'REFUNDED' && status == 'REFUNDED') return true;
            if (selectedFilter == 'EXPIRED' && (status == 'EXPIRED' || status == 'DEPLETED')) return true;
            return false;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(purchasesFutureProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(24),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const PurchaseSummaryCards(
                  totalSpent: 185,
                  totalSavings: 65,
                ),
                const SizedBox(height: 24),
                _buildFilterTabs(ref, selectedFilter),
                const SizedBox(height: 24),
                if (filteredPurchases.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'purchases.empty'.tr(),
                            style: const TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filteredPurchases.map((package) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildPurchaseCard(context, package),
                  )),
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

  Widget _buildFilterTabs(WidgetRef ref, String selectedFilter) {
    final filters = [
      {'id': 'ALL', 'label': 'purchases.filter_all'.tr()},
      {'id': 'COMPLETED', 'label': 'purchases.filter_completed'.tr()},
      {'id': 'REFUNDED', 'label': 'purchases.filter_refunded'.tr()},
      {'id': 'EXPIRED', 'label': 'purchases.filter_expired'.tr()},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => ref.read(purchasesFilterProvider.notifier).state = filter['id']!,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey.shade300,
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
    final isDepleted = status == 'DEPLETED' || status == 'EXPIRED';
    
    // Mapped properties based on design
    final title = package['businessName'] ?? 'Unknown Business';
    final subtitle = package['packageName'] ?? 'Unknown Package';
    // Provide a mocked random price between 30 and 150 for display if not found
    final price = package['price'] ?? (package['packageName'].toString().length * 5).clamp(30, 150).toString();
    
    final businessNameLower = title.toLowerCase();
    Color iconBgColor = const Color(0xFFFFF3E0);
    Color iconColor = const Color(0xFFEF6C00);
    IconData icon = Icons.coffee;
    
    if (businessNameLower.contains('salon') || businessNameLower.contains('beauty')) {
      iconBgColor = const Color(0xFFFCE4EC);
      iconColor = const Color(0xFFC2185B);
      icon = Icons.spa;
    } else if (businessNameLower.contains('restaurant') || businessNameLower.contains('مطعم')) {
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
    } else if (isDepleted) {
      tagBgColor = const Color(0xFFFFEBEE); // Light red
      tagTextColor = const Color(0xFFD32F2F);
      tagText = 'purchases.filter_expired'.tr();
    } else {
      tagBgColor = const Color(0xFFE8F5E9); // Light green
      tagTextColor = const Color(0xFF388E3C);
      tagText = 'purchases.filter_completed'.tr(); // Treating active as completed in this view
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
                      'purchases.currency'.tr(),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: tagBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tagTextColor.withValues(alpha: 0.2)),
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
            if (isDepleted && package['remainingQuantity'] != null && package['remainingQuantity'] > 0) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${package['remainingQuantity']} ${package['packageType'] == 'QUANTITY' ? 'dashboard.items'.tr() : 'dashboard.visits'.tr()} غير مستردة', // Hardcoded fallback for edgecase
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.info, color: Colors.grey, size: 14),
                ],
              ),
            ]
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
}
