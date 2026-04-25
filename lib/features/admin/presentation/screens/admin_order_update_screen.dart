import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Admin/api/admin_order_service.dart';
import 'package:retilda/core/theme/app_theme.dart';
import 'package:retilda/model/purchases.dart';

class AdminOrderUpdateScreen extends ConsumerStatefulWidget {
  const AdminOrderUpdateScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AdminOrderUpdateScreenState();
}

class _AdminOrderUpdateScreenState
    extends ConsumerState<AdminOrderUpdateScreen> {
  final AdminOrderService _service = AdminOrderService();
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _money = NumberFormat('#,##0', 'en_NG');

  List<Purchase> _purchases = [];
  bool _loading = true;
  String _searchQuery = '';

  List<Purchase> get _filteredTracking {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _purchases;
    }

    return _purchases.where((purchase) {
      final name = (purchase.userName ?? '').toLowerCase();
      final email = (purchase.userEmail ?? '').toLowerCase();
      final phone = (purchase.userPhone ?? '').toLowerCase();
      final product = (purchase.product?.name ?? '').toLowerCase();
      return name.contains(query) ||
          email.contains(query) ||
          phone.contains(query) ||
          product.contains(query);
    }).toList();
  }

  int get _deliveryPaidCount => _purchases
      .where((purchase) => purchase.deliveryPaymentStatus == 'paid')
      .length;

  int get _deliveryRequestedCount =>
      _purchases.where((purchase) => purchase.deliveryRequested == true).length;

  int get _readyCount =>
      _purchases.where((purchase) => purchase.orderStatus == 'ready').length;

  Future<void> _loadTracking() async {
    try {
      final response = await _service.getReadyTrackingPurchases();
      if (!mounted) {
        return;
      }
      setState(() {
        _purchases = response.data?.purchasesData ?? [];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    try {
      final response = await _service.getReadyTrackingPurchases();
      if (!mounted) {
        return;
      }
      setState(() {
        _purchases = response.data?.purchasesData ?? [];
      });
    } catch (_) {}
  }

  void _replacePurchase(Purchase updated) {
    final updatedId = updated.id;
    if (updatedId == null) {
      return;
    }

    setState(() {
      final index =
          _purchases.indexWhere((purchase) => purchase.id == updatedId);
      if (index == -1) {
        _purchases.insert(0, updated);
      } else {
        _purchases[index] = updated;
      }
    });
  }

  void _showUpdateFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _updateOrderStatus(String purchaseId, String status) async {
    final updated = await _service.updateOrderStatus(
      purchaseId: purchaseId,
      orderStatus: status,
    );
    if (!mounted) {
      return;
    }

    if (updated == null) {
      _showUpdateFeedback('Order update failed');
      return;
    }

    _replacePurchase(updated);
    _showUpdateFeedback('Order updated');
  }

  Future<void> _updateDeliveryStatus(
    String userId,
    String purchaseId,
    String status,
  ) async {
    if (userId.isEmpty) {
      _showUpdateFeedback('Missing customer details for this purchase');
      return;
    }

    final updated = await _service.updateDeliveryStatus(
      userId: userId,
      purchaseId: purchaseId,
      deliveryStatus: status,
    );
    if (!mounted) {
      return;
    }

    if (updated == null) {
      _showUpdateFeedback('Delivery update failed');
      return;
    }

    _replacePurchase(updated);
    _showUpdateFeedback('Delivery updated');
  }

  Future<void> _markCompleted(String purchaseId) async {
    final updated = await _service.markDeliveryCompleted(purchaseId);
    if (!mounted) {
      return;
    }

    if (updated == null) {
      _showUpdateFeedback('Update failed');
      return;
    }

    _replacePurchase(updated);
    _showUpdateFeedback('Marked completed');
  }

  Future<void> _performTrackingAction(
    Purchase purchase,
    _TrackingAction action,
  ) async {
    final id = purchase.id ?? '';
    if (id.isEmpty) {
      return;
    }

    if ((action == _TrackingAction.deliveryProcessing ||
            action == _TrackingAction.deliveryCompleted) &&
        purchase.deliveryPaymentStatus != 'paid') {
      _showUpdateFeedback(
        'Delivery payment must be paid before moving beyond pending',
      );
      return;
    }

    switch (action) {
      case _TrackingAction.processing:
        await _updateOrderStatus(id, 'processing');
        break;
      case _TrackingAction.ready:
        await _updateOrderStatus(id, 'ready');
        break;
      case _TrackingAction.outForDelivery:
        await _updateOrderStatus(id, 'out_for_delivery');
        break;
      case _TrackingAction.delivered:
        await _updateOrderStatus(id, 'delivered');
        break;
      case _TrackingAction.deliveryPending:
        await _updateDeliveryStatus(purchase.userId ?? '', id, 'pending');
        break;
      case _TrackingAction.deliveryProcessing:
        await _updateDeliveryStatus(purchase.userId ?? '', id, 'processing');
        break;
      case _TrackingAction.deliveryCompleted:
        await _markCompleted(id);
        break;
    }
  }

  Future<void> _showStatusPicker(Purchase purchase) async {
    _TrackingAction? selected;
    bool submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final customerName = purchase.userName ?? 'Customer';
            final productName = purchase.product?.name ?? 'Purchase';
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Update status',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.ink,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Colors.black.withValues(alpha: 0.05),
                            ),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0B3452), Color(0xFF145E8D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              customerName,
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Order status',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _StatusOptionTile(
                        label: 'Processing',
                        subtitle: 'Order is being prepared',
                        selected: selected == _TrackingAction.processing,
                        onTap: () => setModalState(
                          () => selected = _TrackingAction.processing,
                        ),
                      ),
                      _StatusOptionTile(
                        label: 'Ready',
                        subtitle: 'Order is ready for dispatch',
                        selected: selected == _TrackingAction.ready,
                        onTap: () => setModalState(
                            () => selected = _TrackingAction.ready),
                      ),
                      _StatusOptionTile(
                        label: 'Out for delivery',
                        subtitle: 'Rider is currently on the route',
                        selected: selected == _TrackingAction.outForDelivery,
                        onTap: () => setModalState(
                          () => selected = _TrackingAction.outForDelivery,
                        ),
                      ),
                      _StatusOptionTile(
                        label: 'Delivered',
                        subtitle: 'Order has reached the customer',
                        selected: selected == _TrackingAction.delivered,
                        onTap: () => setModalState(
                          () => selected = _TrackingAction.delivered,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Delivery status',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _StatusOptionTile(
                        label: 'Delivery pending',
                        subtitle: 'Delivery exists but has not started',
                        selected: selected == _TrackingAction.deliveryPending,
                        onTap: () => setModalState(
                          () => selected = _TrackingAction.deliveryPending,
                        ),
                      ),
                      _StatusOptionTile(
                        label: 'Delivery processing',
                        subtitle: purchase.deliveryPaymentStatus == 'paid'
                            ? 'Move delivery into active processing'
                            : 'Requires paid delivery before processing',
                        selected:
                            selected == _TrackingAction.deliveryProcessing,
                        onTap: () => setModalState(
                          () => selected = _TrackingAction.deliveryProcessing,
                        ),
                      ),
                      _StatusOptionTile(
                        label: 'Mark delivery completed',
                        subtitle: purchase.deliveryPaymentStatus == 'paid'
                            ? 'Complete the delivery lifecycle for this purchase'
                            : 'Requires paid delivery before completion',
                        selected: selected == _TrackingAction.deliveryCompleted,
                        onTap: () => setModalState(
                          () => selected = _TrackingAction.deliveryCompleted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: selected == null || submitting
                              ? null
                              : () async {
                                  setModalState(() => submitting = true);
                                  Navigator.pop(context);
                                  await _performTrackingAction(
                                      purchase, selected!);
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline_rounded),
                          label: const Text('Confirm update'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadTracking();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatMoney(num value) {
    return 'N${_money.format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    final filteredTracking = _filteredTracking;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        surfaceTintColor: AppTheme.surface,
        titleSpacing: 16,
        title: Text(
          'Update tracking',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -30,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent.withValues(alpha: 0.07),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: -50,
            child: IgnorePointer(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.ocean.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),
          if (_loading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: LinearProgressIndicator(color: AppTheme.accent),
              ),
            )
          else
            RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                children: [
                  _TrackingHeroCard(
                    queueCount: _purchases.length,
                    readyCount: _readyCount,
                    paidDeliveryCount: _deliveryPaidCount,
                    requestedCount: _deliveryRequestedCount,
                  ),
                  const SizedBox(height: 16),
                  _SearchBar(
                    controller: _searchController,
                    onChanged: (value) => setState(() {
                      _searchQuery = value;
                    }),
                  ),
                  const SizedBox(height: 18),
                  if (_purchases.isEmpty)
                    const _EmptyTrackingState()
                  else if (filteredTracking.isEmpty)
                    const _EmptyTrackingState(
                      title: 'No matching purchases',
                      subtitle:
                          'Try a different customer name, email, phone, or product keyword.',
                    )
                  else
                    ...filteredTracking.map(
                      (purchase) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _TrackingCard(
                          purchase: purchase,
                          amountText:
                              '${_formatMoney(purchase.totalPaidComputed)} of ${_formatMoney(purchase.totalToPayComputed)}',
                          onTap: () => _showStatusPicker(purchase),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

enum _TrackingAction {
  processing,
  ready,
  outForDelivery,
  delivered,
  deliveryPending,
  deliveryProcessing,
  deliveryCompleted,
}

class _TrackingHeroCard extends StatelessWidget {
  final int queueCount;
  final int readyCount;
  final int paidDeliveryCount;
  final int requestedCount;

  const _TrackingHeroCard({
    required this.queueCount,
    required this.readyCount,
    required this.paidDeliveryCount,
    required this.requestedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B3452), Color(0xFF145E8D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.16),
            blurRadius: 26,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child:
                  const Icon(Icons.local_shipping_rounded, color: Colors.white),
            ),
            const SizedBox(height: 18),
            Text(
              '$queueCount tracking items',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 31,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Customer, product, and delivery-payment details now come directly from the tracking queue.',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.76),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _HeroStat(label: 'Ready', value: '$readyCount'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeroStat(
                    label: 'Delivery paid',
                    value: '$paidDeliveryCount',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeroStat(
                    label: 'Requested',
                    value: '$requestedCount',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  final Purchase purchase;
  final String amountText;
  final VoidCallback onTap;

  const _TrackingCard({
    required this.purchase,
    required this.amountText,
    required this.onTap,
  });

  Color _statusColor(String? value) {
    switch (value) {
      case 'paid':
      case 'completed':
      case 'delivered':
        return const Color(0xFF1E8E5A);
      case 'ready':
      case 'processing':
        return AppTheme.ocean;
      case 'pending':
      case 'out_for_delivery':
        return AppTheme.accent;
      default:
        return AppTheme.ink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = purchase.product?.images?.isNotEmpty == true
        ? purchase.product!.images!.first
        : '';
    final customerLabel = purchase.userName ?? 'Customer';
    final deliveryPaymentLabel =
        purchase.deliveryPaymentStatus?.replaceAll('_', ' ') ?? 'not started';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.ink.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFFF1F4F8),
                      image: imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: imageUrl.isEmpty
                        ? Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.grey[400],
                            size: 30,
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          purchase.product?.name ?? 'Purchase',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          customerLabel,
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withValues(alpha: 0.56),
                          ),
                        ),
                        if ((purchase.userEmail ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            purchase.userEmail!,
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                              color: Colors.black.withValues(alpha: 0.42),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.black.withValues(alpha: 0.32),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _TrackingMetric(
                      label: 'Collected',
                      value: amountText,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TrackingMetric(
                      label: 'Phone',
                      value: (purchase.userPhone ?? '').isEmpty
                          ? 'Unavailable'
                          : purchase.userPhone!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Pill(
                    label: purchase.paymentPlan ?? 'no plan',
                    color: AppTheme.ink,
                  ),
                  _Pill(
                    label: purchase.orderStatus ?? 'unknown order',
                    color: _statusColor(purchase.orderStatus),
                  ),
                  _Pill(
                    label: purchase.deliveryStatus ?? 'unknown delivery',
                    color: _statusColor(purchase.deliveryStatus),
                  ),
                  _Pill(
                    label: 'delivery $deliveryPaymentLabel',
                    color: _statusColor(purchase.deliveryPaymentStatus),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tap to update tracking status',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackingMetric extends StatelessWidget {
  final String label;
  final String value;

  const _TrackingMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.46),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.replaceAll('_', ' '),
        style: GoogleFonts.manrope(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _StatusOptionTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _StatusOptionTile({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = selected ? AppTheme.accent : AppTheme.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              selected ? AppTheme.accent.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.accent.withValues(alpha: 0.3)
                : AppTheme.ink.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent, width: 1.5),
                color: selected ? accent : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withValues(alpha: 0.52),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.ink.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.manrope(
          fontWeight: FontWeight.w700,
          color: AppTheme.ink,
        ),
        decoration: InputDecoration(
          hintText: 'Search customer, phone, email, or product',
          hintStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            color: Colors.black.withValues(alpha: 0.42),
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.ocean),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _EmptyTrackingState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyTrackingState({
    this.title = 'No tracking items yet',
    this.subtitle =
        'No purchases were returned from the tracking queue for the selected statuses.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          const Icon(Icons.track_changes_rounded,
              size: 42, color: AppTheme.ocean),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
