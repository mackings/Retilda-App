import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/OrderTracking/views/order_tracking_screen.dart';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/core/theme/app_theme.dart';
import 'package:retilda/model/purchases.dart';

class OrderTrackingListScreen extends ConsumerStatefulWidget {
  const OrderTrackingListScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _OrderTrackingListScreenState();
}

class _OrderTrackingListScreenState
    extends ConsumerState<OrderTrackingListScreen> {
  late final AppSession _session = AppSession();
  late final ApiClient _apiClient = ApiClient(session: _session);
  List<Purchase> _purchases = [];
  bool _isLoading = true;
  String? _token;
  String? _userId;

  Future<PurchaseResponse> _fetchPurchases(String userId, String token) async {
    final response = await _apiClient.get('getAllPendingPurchases');

    if (response.statusCode == 200) {
      return PurchaseResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load purchases');
    }
  }

  Future<void> _loadUserData() async {
    final userData = await _session.userData();
    final token = await _session.userToken();
    if (userData == null || token == null) {
      setState(() => _isLoading = false);
      return;
    }

    final userId = userData['data']['user']['_id'] as String;
    setState(() {
      _token = token;
      _userId = userId;
    });

    try {
      final response = await _fetchPurchases(userId, token);
      setState(() {
        _purchases = response.data?.purchasesData ?? [];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    if (_token == null || _userId == null) return;
    try {
      final response = await _fetchPurchases(_userId!, _token!);
      setState(() {
        _purchases = response.data?.purchasesData ?? [];
      });
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  String _labelForStatus(String value) {
    switch (value) {
      case 'ready':
        return 'Ready';
      case 'out_for_delivery':
        return 'Out for delivery';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      default:
        return 'Processing';
    }
  }

  Color _statusColor(String value) {
    switch (value) {
      case 'ready':
        return const Color(0xFF8A5B00);
      case 'out_for_delivery':
        return const Color(0xFF145E8D);
      case 'delivered':
      case 'completed':
        return const Color(0xFF0E7C66);
      default:
        return AppTheme.accent;
    }
  }

  String _planLabel(Purchase purchase) {
    if (purchase.paymentPlan == 'once') return 'One-time payment';
    final type = purchase.purchaseType ?? purchase.paymentPlan ?? 'Installment';
    return type.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFF6F7FB);
    const Color accent = Color(0xFFFB9324);

    final inMotionCount = _purchases
        .where(
          (purchase) =>
              purchase.deliveryStatus == 'processing' ||
              purchase.orderStatus == 'out_for_delivery',
        )
        .length;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        title: Text(
          'Order tracking',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
            letterSpacing: -0.6,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: LinearProgressIndicator(color: accent),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _purchases.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: const [
                        _EmptyTrackingListState(),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _purchases.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF0C3554),
                                  Color(0xFF145E8D),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.10),
                                  blurRadius: 22,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Follow every order in one place',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Track progress, delivery status, and payment completion across all your purchases.',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13.5,
                                    height: 1.45,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _HeroMetric(
                                        label: 'Tracked orders',
                                        value: '${_purchases.length}',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _HeroMetric(
                                        label: 'In motion',
                                        value: '$inMotionCount',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }

                        final purchase = _purchases[index - 1];
                        final dateValue = purchase.payments?.isNotEmpty == true
                            ? purchase.payments!.first.paymentDate ??
                                purchase.payments!.first.nextPaymentDate
                            : null;
                        final paymentDate = dateValue != null
                            ? DateTime.tryParse(dateValue) ?? DateTime.now()
                            : DateTime.now();
                        final totalToPay = purchase.totalToPayComputed;
                        final totalPaid = purchase.totalPaidComputed;
                        final progress = totalToPay == 0
                            ? 0.0
                            : (totalPaid / totalToPay).clamp(0, 1).toDouble();
                        final orderStatus =
                            purchase.orderStatus ?? 'processing';
                        final deliveryStatus =
                            purchase.deliveryStatus ?? 'processing';
                        final statusColor = _statusColor(orderStatus);

                        return InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderTrackingScreen(
                                  purchaseId: purchase.id ?? '',
                                  productName: purchase.product?.name,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 18,
                                  offset: const Offset(0, 12),
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
                                      height: 52,
                                      width: 52,
                                      decoration: BoxDecoration(
                                        color:
                                            statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Icon(
                                        orderStatus == 'out_for_delivery'
                                            ? Icons.local_shipping_outlined
                                            : orderStatus == 'delivered'
                                                ? Icons
                                                    .check_circle_outline_rounded
                                                : Icons.inventory_2_outlined,
                                        color: statusColor,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            purchase.product?.name ??
                                                'Purchase',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.ink,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            DateFormat('dd MMM yyyy')
                                                .format(paymentDate),
                                            style: GoogleFonts.manrope(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black
                                                  .withValues(alpha: 0.56),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _TrackingPill(
                                      label: _labelForStatus(orderStatus),
                                      color: statusColor,
                                    ),
                                    _TrackingPill(
                                      label: _planLabel(purchase),
                                      color: AppTheme.accent,
                                    ),
                                    _TrackingPill(
                                      label:
                                          'Delivery ${_labelForStatus(deliveryStatus)}',
                                      color: _statusColor(deliveryStatus),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _TrackingMetric(
                                              label: 'Paid',
                                              value:
                                                  'N${NumberFormat('#,##0').format(totalPaid)}',
                                            ),
                                          ),
                                          Expanded(
                                            child: _TrackingMetric(
                                              label: 'Total',
                                              value:
                                                  'N${NumberFormat('#,##0').format(totalToPay)}',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 8,
                                          backgroundColor:
                                              const Color(0xFFE6ECF2),
                                          color: AppTheme.ocean,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${(progress * 100).round()}% complete',
                                              style: GoogleFonts.manrope(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.black
                                                    .withValues(alpha: 0.56),
                                              ),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.black45,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingPill extends StatelessWidget {
  const _TrackingPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _TrackingMetric extends StatelessWidget {
  const _TrackingMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black.withValues(alpha: 0.54),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

class _EmptyTrackingListState extends StatelessWidget {
  const _EmptyTrackingListState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 34, 22, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 68,
            width: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.track_changes_rounded,
              size: 34,
              color: AppTheme.ocean,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No tracked orders yet',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your order updates will appear here once you complete your first purchase.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }
}
