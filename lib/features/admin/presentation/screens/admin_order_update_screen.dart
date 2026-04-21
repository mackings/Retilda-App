import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Admin/api/admin_order_service.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/purchases.dart';
import 'package:sizer/sizer.dart';

class AdminOrderUpdateScreen extends ConsumerStatefulWidget {
  const AdminOrderUpdateScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AdminOrderUpdateScreenState();
}

class _AdminOrderUpdateScreenState
    extends ConsumerState<AdminOrderUpdateScreen> {
  final AdminOrderService _service = AdminOrderService();
  List<Purchase> _purchases = [];
  bool _loading = true;
  String _searchQuery = '';

  List<Purchase> get _trackingEligible {
    return _purchases.where((purchase) {
      final totalToPay = purchase.totalToPayComputed;
      final totalPaid = purchase.totalPaidComputed;
      final paidRatio =
          (totalToPay != null && totalToPay > 0) ? (totalPaid / totalToPay) : 0;
      final typeAllows = purchase.purchaseType == 'down_40' ||
          purchase.purchaseType == 'down_50';
      final percentAllows = (purchase.downPaymentPercent ?? 0) >= 0.4;
      return purchase.hasPaidDownPayment ||
          paidRatio >= 0.4 ||
          typeAllows ||
          percentAllows;
    }).toList();
  }

  List<Purchase> get _filteredTracking {
    final source = _trackingEligible;
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return source;
    return source.where((purchase) {
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

  Future<void> _loadTracking() async {
    try {
      final response = await _service.getReadyTrackingPurchases();
      setState(() {
        _purchases = response.data?.purchasesData ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    try {
      final response = await _service.getReadyTrackingPurchases();
      setState(() {
        _purchases = response.data?.purchasesData ?? [];
      });
    } catch (_) {}
  }

  Future<void> _updateOrderStatus(String purchaseId, String status) async {
    final ok = await _service.updateOrderStatus(
      purchaseId: purchaseId,
      orderStatus: status,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Order updated' : 'Update failed')),
    );
  }

  Future<void> _updateDeliveryStatus(
      String userId, String purchaseId, String status) async {
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing userId for this purchase')),
      );
      return;
    }
    final ok = await _service.updateDeliveryStatus(
      userId: userId,
      purchaseId: purchaseId,
      deliveryStatus: status,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Delivery updated' : 'Update failed')),
    );
  }

  Future<void> _markCompleted(String purchaseId) async {
    final ok = await _service.markDeliveryCompleted(purchaseId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Marked completed' : 'Update failed')),
    );
  }

  Future<void> _showStatusPicker(Purchase purchase) async {
    const Color deepBlue = Color(0xFF103C57);
    const Color accent = Color(0xFFFB9324);
    _TrackingAction? selected;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    CustomText(
                      'Update status',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: deepBlue,
                    ),
                    const SizedBox(height: 12),
                    _StatusOptionTile(
                      label: 'Processing',
                      subtitle: 'Order is being prepared',
                      selected: selected == _TrackingAction.processing,
                      onTap: () => setModalState(
                          () => selected = _TrackingAction.processing),
                    ),
                    _StatusOptionTile(
                      label: 'Ready',
                      subtitle: 'Order is ready for delivery',
                      selected: selected == _TrackingAction.ready,
                      onTap: () =>
                          setModalState(() => selected = _TrackingAction.ready),
                    ),
                    _StatusOptionTile(
                      label: 'Out for delivery',
                      subtitle: 'Rider is on the way',
                      selected: selected == _TrackingAction.outForDelivery,
                      onTap: () => setModalState(
                          () => selected = _TrackingAction.outForDelivery),
                    ),
                    _StatusOptionTile(
                      label: 'Delivered',
                      subtitle: 'Order delivered to customer',
                      selected: selected == _TrackingAction.delivered,
                      onTap: () => setModalState(
                          () => selected = _TrackingAction.delivered),
                    ),
                    const SizedBox(height: 8),
                    _StatusOptionTile(
                      label: 'Delivery processing',
                      subtitle: 'Update delivery status to processing',
                      selected: selected == _TrackingAction.deliveryProcessing,
                      onTap: () => setModalState(
                          () => selected = _TrackingAction.deliveryProcessing),
                    ),
                    _StatusOptionTile(
                      label: 'Mark delivery completed',
                      subtitle: 'Complete delivery for this purchase',
                      selected: selected == _TrackingAction.deliveryCompleted,
                      onTap: () => setModalState(
                          () => selected = _TrackingAction.deliveryCompleted),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: selected == null
                            ? null
                            : () async {
                                Navigator.pop(context);
                                final id = purchase.id ?? '';
                                if (id.isEmpty) return;
                                switch (selected) {
                                  case _TrackingAction.processing:
                                    await _updateOrderStatus(id, 'processing');
                                    break;
                                  case _TrackingAction.ready:
                                    await _updateOrderStatus(id, 'ready');
                                    break;
                                  case _TrackingAction.outForDelivery:
                                    await _updateOrderStatus(
                                        id, 'out_for_delivery');
                                    break;
                                  case _TrackingAction.delivered:
                                    await _updateOrderStatus(id, 'delivered');
                                    break;
                                  case _TrackingAction.deliveryProcessing:
                                    await _updateDeliveryStatus(
                                      purchase.userId ?? '',
                                      id,
                                      'processing',
                                    );
                                    break;
                                  case _TrackingAction.deliveryCompleted:
                                    await _markCompleted(id);
                                    break;
                                  case null:
                                    break;
                                }
                              },
                        child: const Text('Confirm update'),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
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
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFF6F7FB);
    const Color deepBlue = Color(0xFF103C57);
    const Color accent = Color(0xFFFB9324);

    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            backgroundColor: pageBg,
            title: CustomText(
              'Update tracking',
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: deepBlue,
            ),
          ),
          body: _loading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: LinearProgressIndicator(color: accent),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: _trackingEligible.isEmpty
                      ? ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 140),
                              child: Column(
                                children: [
                                  Icon(Icons.track_changes,
                                      size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  CustomText(
                                    'No tracking items yet',
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                    color: deepBlue,
                                  ),
                                  const SizedBox(height: 6),
                                  CustomText(
                                    'Only purchases with 40% or more paid show here.',
                                    fontSize: 13.sp,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          itemCount: _filteredTracking.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _SearchBar(
                                onChanged: (value) => setState(() {
                                  _searchQuery = value;
                                }),
                              );
                            }
                            final purchase = _filteredTracking[index - 1];
                            final totalPaid = purchase.totalPaidComputed;
                            final totalToPay = purchase.totalToPayComputed;
                            final amountText =
                                'N${NumberFormat('#,##0').format(totalPaid)} of N${NumberFormat('#,##0').format(totalToPay)}';

                            return _TrackingCard(
                              purchase: purchase,
                              amountText: amountText,
                              onTap: () => _showStatusPicker(purchase),
                            );
                          },
                        ),
                ),
        );
      },
    );
  }
}

enum _TrackingAction {
  processing,
  ready,
  outForDelivery,
  delivered,
  deliveryProcessing,
  deliveryCompleted,
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

  @override
  Widget build(BuildContext context) {
    const Color deepBlue = Color(0xFF103C57);
    const Color accent = Color(0xFFFB9324);
    final imageUrl = purchase.product?.images?.isNotEmpty == true
        ? purchase.product!.images!.first
        : '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.grey[100],
                    image: imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imageUrl.isEmpty
                      ? Icon(Icons.image_outlined,
                          color: Colors.grey[400], size: 26)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        purchase.product?.name ?? 'Purchase',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: deepBlue,
                      ),
                      const SizedBox(height: 6),
                      CustomText(
                        amountText,
                        fontSize: 13.sp,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (purchase.paymentPlan != null)
                            _Pill(label: purchase.paymentPlan!),
                          if (purchase.orderStatus != null)
                            _Pill(label: purchase.orderStatus!),
                          if (purchase.deliveryStatus != null)
                            _Pill(label: purchase.deliveryStatus!),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    'Tap to update',
                    fontSize: 12.sp,
                    color: accent,
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

class _Pill extends StatelessWidget {
  final String label;

  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.replaceAll('_', ' '),
        style: const TextStyle(fontSize: 12, color: Colors.black87),
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
    const Color accent = Color(0xFFFB9324);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.08) : Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: selected,
              activeColor: accent,
              onChanged: (_) => onTap(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
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
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search by name or product',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
