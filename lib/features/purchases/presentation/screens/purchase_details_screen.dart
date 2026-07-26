import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:zouz_mobile/features/purchases/repositories/purchases_repository.dart';

class PurchaseDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> package;

  const PurchaseDetailScreen({super.key, required this.package});

  @override
  ConsumerState<PurchaseDetailScreen> createState() =>
      _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends ConsumerState<PurchaseDetailScreen> {
  Map<String, dynamic>? _details;
  final Map<String, int> _selectedQuantities = {};
  Map<String, dynamic>? _intent;
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref
          .read(purchasesRepositoryProvider)
          .fetchPurchaseDetails(widget.package['id'].toString());
      if (!mounted) return;
      setState(() {
        _details = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _createIntent() async {
    final details = _details;
    if (details == null) return;
    final isItemized = details['redemptionMode'] == 'ITEMIZED';
    final selected = _selectedQuantities.entries
        .where((entry) => entry.value > 0)
        .map((entry) => {'balanceId': entry.key, 'quantity': entry.value})
        .toList();
    if (isItemized && selected.isEmpty) {
      setState(() => _error = 'purchases.select_item_error'.tr());
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final intent = await ref
          .read(purchasesRepositoryProvider)
          .createRedemptionIntent(
            orderItemId: details['id'].toString(),
            items: selected,
          );
      if (!mounted) return;
      setState(() {
        _intent = intent;
        _submitting = false;
      });
      _startCountdown(DateTime.parse(intent['expiresAt'].toString()));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _submitting = false;
      });
    }
  }

  void _startCountdown(DateTime expiresAt) {
    _timer?.cancel();
    void update() {
      final seconds = expiresAt.difference(DateTime.now()).inSeconds;
      if (!mounted) return;
      setState(() => _secondsRemaining = seconds.clamp(0, 3600));
      if (seconds <= 0) _timer?.cancel();
    }

    update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => update());
  }

  Future<void> _cancelIntent() async {
    final intentId = _intent?['intentId']?.toString();
    _timer?.cancel();
    setState(() {
      _intent = null;
      _secondsRemaining = 0;
      _error = null;
    });
    if (intentId == null) return;
    try {
      await ref
          .read(purchasesRepositoryProvider)
          .cancelRedemptionIntent(intentId);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _refreshIntent() async {
    await _cancelIntent();
    if (mounted) await _createIntent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        title: Text(
          'purchases.details_title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _details == null
          ? _errorState()
          : RefreshIndicator(
              onRefresh: _loadDetails,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _header(),
                  const SizedBox(height: 16),
                  if (_error != null) _errorBanner(),
                  if (_error != null) const SizedBox(height: 12),
                  if (_intent != null) _qrCard() else _selectionCard(),
                  const SizedBox(height: 16),
                  _packageSummary(),
                  const SizedBox(height: 16),
                  _historyCard(),
                ],
              ),
            ),
    );
  }

  Widget _errorState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_error ?? 'purchases.details_load_error'.tr()),
        TextButton(onPressed: _loadDetails, child: Text('common.retry'.tr())),
      ],
    ),
  );

  Widget _header() {
    final details = _details!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            details['packageName']?.toString() ?? '',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            details['businessName']?.toString() ?? '',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _selectionCard() {
    final details = _details!;
    final isItemized = details['redemptionMode'] == 'ITEMIZED';
    final balances = List<Map<String, dynamic>>.from(
      details['itemBalances'] ?? const [],
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isItemized
                ? 'purchases.select_items'.tr()
                : 'purchases.redeem_one_use'.tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          if (isItemized) ...[
            const SizedBox(height: 12),
            ...balances.map(_itemSelector),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: details['status'] == 'ACTIVE' && !_submitting
                ? _createIntent
                : null,
            icon: _submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.qr_code_2),
            label: Text('purchases.generate_qr'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _itemSelector(Map<String, dynamic> item) {
    final id = item['id'].toString();
    final remaining = (item['remainingQuantity'] as num?)?.toInt() ?? 0;
    final quantity = _selectedQuantities[id] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: quantity > 0 ? AppColors.primary : Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name']?.toString() ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  'purchases.remaining_count'.tr(args: ['$remaining']),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: quantity > 0
                ? () => setState(() => _selectedQuantities[id] = quantity - 1)
                : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            '$quantity',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          IconButton(
            onPressed: quantity < remaining
                ? () => setState(() => _selectedQuantities[id] = quantity + 1)
                : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  Widget _qrCard() {
    final expired = _secondsRemaining <= 0;
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(
            expired ? 'purchases.qr_expired'.tr() : 'purchases.qr_title'.tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          if (!expired)
            QrImageView(
              data: _intent!['qrData'].toString(),
              version: QrVersions.auto,
              size: 220,
            )
          else
            const Icon(Icons.timer_off_outlined, size: 100, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            expired
                ? 'purchases.qr_refresh_instruction'.tr()
                : 'purchases.qr_expires_in'.tr(args: ['$minutes:$seconds']),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelIntent,
                  child: Text('common.cancel'.tr()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _submitting ? null : _refreshIntent,
                  child: Text('purchases.refresh_qr'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _packageSummary() {
    final details = _details!;
    final balances = List<Map<String, dynamic>>.from(
      details['itemBalances'] ?? const [],
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'purchases.package_details'.tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (details['redemptionMode'] == 'ITEMIZED')
            ...balances.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item['name']?.toString() ?? ''),
                subtitle: item['description']?.toString().isNotEmpty == true
                    ? Text(item['description'].toString())
                    : null,
                trailing: Text(
                  '${item['remainingQuantity']} / ${item['initialQuantity']}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            )
          else
            Text(
              '${details['remainingQuantity'] ?? '—'} / ${details['initialQuantity'] ?? '—'} ${'purchases.usages_remaining'.tr()}',
            ),
        ],
      ),
    );
  }

  Widget _historyCard() {
    final history = List<Map<String, dynamic>>.from(
      _details!['redemptions'] ?? const [],
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'purchases.redemption_history'.tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (history.isEmpty)
            Text(
              'purchases.no_redemptions'.tr(),
              style: const TextStyle(color: AppColors.textSecondary),
            )
          else
            ...history.map((redemption) {
              final items = List<Map<String, dynamic>>.from(
                redemption['items'] ?? const [],
              );
              final date = DateTime.tryParse(
                redemption['redeemedAt']?.toString() ?? '',
              );
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(
                  items.isEmpty
                      ? 'purchases.redeem_one_use'.tr()
                      : items
                            .map(
                              (item) => '${item['name']} × ${item['quantity']}',
                            )
                            .join(', '),
                ),
                subtitle: Text(
                  [
                    if (date != null) DateFormat.yMMMd().add_jm().format(date),
                    redemption['standName']?.toString() ?? '',
                  ].where((value) => value.isNotEmpty).join(' • '),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _errorBanner() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 14,
        offset: const Offset(0, 5),
      ),
    ],
  );
}
