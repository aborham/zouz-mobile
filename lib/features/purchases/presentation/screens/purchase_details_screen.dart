import 'dart:async';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:zouz_mobile/features/dashboard/providers/home_provider.dart';
import 'package:zouz_mobile/features/purchases/repositories/purchases_repository.dart';

class PurchaseDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> package;

  const PurchaseDetailScreen({super.key, required this.package});

  @override
  ConsumerState<PurchaseDetailScreen> createState() =>
      _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends ConsumerState<PurchaseDetailScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _details;
  final Map<String, int> _selectedQuantities = {};
  Map<String, dynamic>? _intent;
  Timer? _timer;
  Timer? _redemptionPoller;
  int _secondsRemaining = 0;
  bool _loading = true;
  bool _submitting = false;
  bool _submittingRefund = false;
  bool _pollingDetails = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDetails();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _redemptionPoller?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDetails(showLoading: false);
    }
  }

  Future<void> _loadDetails({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final previousRemaining = _remainingUnits(_details);
      final data = await ref
          .read(purchasesRepositoryProvider)
          .fetchPurchaseDetails(widget.package['id'].toString());
      if (!mounted) return;
      final currentRemaining = _remainingUnits(data);
      setState(() {
        _details = data;
        _loading = false;
        _error = null;
      });
      if (previousRemaining != null && previousRemaining != currentRemaining) {
        ref.invalidate(homeDataProvider);
      }
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
    final isItemized = _isItemized(details);
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
      _startRedemptionPolling();
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
    _redemptionPoller?.cancel();
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

  void _startRedemptionPolling() {
    _redemptionPoller?.cancel();
    _redemptionPoller = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollForCompletedRedemption();
    });
  }

  Future<void> _pollForCompletedRedemption() async {
    if (_pollingDetails || _intent == null || !mounted) return;
    _pollingDetails = true;
    try {
      final previousRedemptions =
          (_details?['redemptions'] as List?)?.length ?? 0;
      final data = await ref
          .read(purchasesRepositoryProvider)
          .fetchPurchaseDetails(widget.package['id'].toString());
      if (!mounted) return;

      final currentRedemptions = (data['redemptions'] as List?)?.length ?? 0;
      final redemptionCompleted = currentRedemptions > previousRedemptions;
      setState(() {
        _details = data;
        if (redemptionCompleted) {
          _intent = null;
          _secondsRemaining = 0;
          _selectedQuantities.clear();
        }
      });

      if (redemptionCompleted) {
        _timer?.cancel();
        _redemptionPoller?.cancel();
        ref.invalidate(homeDataProvider);
      }
    } catch (_) {
      // A transient refresh failure must not interrupt the active QR flow.
    } finally {
      _pollingDetails = false;
    }
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
              onRefresh: () => _loadDetails(showLoading: false),
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
                  const SizedBox(height: 16),
                  _refundSection(),
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
            _localizedValue(details['packageName']),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            _localizedValue(details['businessName']),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _selectionCard() {
    final details = _details!;
    final balances = List<Map<String, dynamic>>.from(
      details['itemBalances'] ?? const [],
    );
    final isItemized = _isItemized(details);
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
    final manualCode = _intent?['manualCode']?.toString().trim() ?? '';
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
          if (!expired && manualCode.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'purchases.manual_code_instruction'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 8, 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: SelectableText(
                        manualCode,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'purchases.copy_manual_code'.tr(),
                    onPressed: () => _copyManualCode(manualCode),
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'purchases.manual_code_expiry'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
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

  Future<void> _copyManualCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('purchases.manual_code_copied'.tr())),
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
          if (_isItemized(details))
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
            _simpleUsageSummary(details),
        ],
      ),
    );
  }

  Widget _simpleUsageSummary(Map<String, dynamic> details) {
    final initial = (details['initialQuantity'] as num?)?.toInt();
    final remaining = (details['remainingQuantity'] as num?)?.toInt();
    if (initial == null || remaining == null) {
      return const Text('—');
    }
    final used = (initial - remaining).clamp(0, initial);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$used / $initial ${'purchases.usages_used'.tr()}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'purchases.remaining_count'.tr(args: ['$remaining']),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  int? _remainingUnits(Map<String, dynamic>? details) {
    if (details == null) return null;
    final balances = details['itemBalances'];
    if (details['redemptionMode'] == 'ITEMIZED' && balances is List) {
      return balances.fold<int>(
        0,
        (sum, item) =>
            sum + ((item as Map)['remainingQuantity'] as num? ?? 0).toInt(),
      );
    }
    return (details['remainingQuantity'] as num?)?.toInt();
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
                              (item) =>
                                  '${_localizedValue(item['name'])} × ${item['quantity']}',
                            )
                            .join(', '),
                ),
                subtitle: Text(
                  [
                    if (date != null) DateFormat.yMMMd().add_jm().format(date),
                    _localizedValue(redemption['standName']),
                  ].where((value) => value.isNotEmpty).join(' • '),
                ),
              );
            }),
        ],
      ),
    );
  }

  bool _isItemized(Map<String, dynamic> details) {
    final balances = details['itemBalances'];
    return details['redemptionMode'] == 'ITEMIZED' &&
        balances is List &&
        balances.isNotEmpty;
  }

  String _localizedValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) {
      final locale = context.locale.languageCode;
      return (value[locale] ?? value['en'] ?? value['ar'] ?? '').toString();
    }
    return value.toString();
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

  Widget _refundSection() {
    final details = _details;
    if (details == null) return const SizedBox.shrink();

    final status = details['status']?.toString();
    final disputeStatus = details['disputeStatus']?.toString() ?? 'NONE';
    final isRefunded = status == 'REFUNDED' || disputeStatus == 'RESOLVED';
    final isPendingDispute = disputeStatus == 'PENDING';
    final isExpired = status == 'EXPIRED';

    final purchaseDateStr = details['purchaseDate']?.toString();
    final purchaseDate = purchaseDateStr != null ? DateTime.tryParse(purchaseDateStr) : null;
    final ageInDays = purchaseDate != null
        ? DateTime.now().difference(purchaseDate).inDays
        : 999;
    final isWithin7Days = ageInDays <= 7;

    final redemptions = details['redemptions'] as List? ?? [];
    final hasUsage = redemptions.isNotEmpty || details['firstActivatedAt'] != null;
    final isEligibleInstant = isWithin7Days && !hasUsage && !isExpired && !isRefunded && !isPendingDispute;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.security_update_good_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'purchases.refund_title'.tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isRefunded)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'purchases.refund_status_refunded'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (isPendingDispute)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.hourglass_empty_rounded, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'purchases.refund_status_dispute'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (isExpired)
            Text(
              'purchases.refund_ineligible_expired'.tr(),
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            )
          else if (isEligibleInstant) ...[
            Text(
              'purchases.refund_instant_desc'.tr(),
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _submittingRefund ? null : () => _showRefundDialog(isInstant: true),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: _submittingRefund
                  ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.replay_rounded),
              label: Text('purchases.refund_instant_btn'.tr()),
            ),
          ] else ...[
            Text(
              'purchases.refund_dispute_desc'.tr(),
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _submittingRefund ? null : () => _showRefundDialog(isInstant: false),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade800,
                side: BorderSide(color: Colors.orange.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.report_problem_outlined),
              label: Text('purchases.refund_dispute_btn'.tr()),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showRefundDialog({required bool isInstant}) async {
    final details = _details;
    if (details == null) return;
    final orderId = details['orderId']?.toString();
    final itemId = details['id']?.toString();
    if (orderId == null || itemId == null) return;

    String selectedReason = 'purchases.refund_reason_mistake'.tr();
    final reasons = [
      'purchases.refund_reason_mistake'.tr(),
      'purchases.refund_reason_mind'.tr(),
      'purchases.refund_reason_service'.tr(),
      'purchases.refund_reason_other'.tr(),
    ];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isInstant
                  ? 'purchases.refund_confirm_title'.tr()
                  : 'purchases.refund_dispute_btn'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isInstant
                      ? 'purchases.refund_confirm_msg'.tr()
                      : 'purchases.refund_dispute_desc'.tr()),
                  const SizedBox(height: 16),
                  Text(
                    'purchases.refund_reason_prompt'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedReason,
                    isExpanded: true,
                    items: reasons
                        .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedReason = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text('common.cancel'.tr()),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: isInstant ? Colors.red.shade700 : AppColors.primary,
                  ),
                  child: Text(isInstant ? 'purchases.refund_instant_btn'.tr() : 'common.done'.tr()),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _submittingRefund = true);
    try {
      final res = await ref.read(purchasesRepositoryProvider).submitRefundOrDispute(
            orderId: orderId,
            itemId: itemId,
            reason: selectedReason,
          );
      if (!mounted) return;
      final isAuto = res['autoRefunded'] == true;
      final msg = isAuto
          ? 'purchases.refund_success_msg'.tr()
          : 'purchases.dispute_submitted_msg'.tr();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: isAuto ? Colors.green : Colors.orange.shade800),
      );
      await _loadDetails(showLoading: false);
      ref.invalidate(homeDataProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _submittingRefund = false);
    }
  }
}
