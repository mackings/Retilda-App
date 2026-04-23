import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retilda/Views/OrderTracking/api/order_status_service.dart';
import 'package:retilda/Views/OrderTracking/widgets/order_timeline.dart';
import 'package:retilda/core/theme/app_theme.dart';
import 'package:retilda/model/order_status.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String purchaseId;
  final String? productName;

  const OrderTrackingScreen({
    super.key,
    required this.purchaseId,
    this.productName,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  final OrderStatusService _service = OrderStatusService();

  bool _loading = true;
  OrderStatusData? _statusData;

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    final response = await _service.getOrderStatus(widget.purchaseId);
    setState(() {
      _statusData = response.data;
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  String _labelForStatus(String value) {
    switch (value) {
      case 'processing':
        return 'Processing';
      case 'ready':
        return 'Ready';
      case 'out_for_delivery':
        return 'Out for delivery';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      default:
        return value.replaceAll('_', ' ');
    }
  }

  String _heroMessage(String value) {
    switch (value) {
      case 'ready':
        return 'Your order is packed and waiting for dispatch.';
      case 'out_for_delivery':
        return 'Delivery is currently in motion.';
      case 'delivered':
        return 'This order has reached its destination.';
      default:
        return 'We are actively working on this order for you.';
    }
  }

  Color _statusColor(String value) {
    switch (value) {
      case 'delivered':
      case 'completed':
        return const Color(0xFF0E7C66);
      case 'out_for_delivery':
        return const Color(0xFF145E8D);
      case 'ready':
        return const Color(0xFF8A5B00);
      default:
        return AppTheme.accent;
    }
  }

  IconData _heroIcon(String value) {
    switch (value) {
      case 'ready':
        return Icons.inventory_2_outlined;
      case 'out_for_delivery':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.hourglass_bottom_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFF6F7FB);
    const Color accent = Color(0xFFFB9324);

    final orderStatus = _statusData?.orderStatus ?? 'processing';
    final deliveryStatus = _statusData?.deliveryStatus ?? 'processing';
    final paymentPlan = _statusData?.paymentPlan ?? 'monthly';
    final statusColor = _statusColor(orderStatus);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        title: Text(
          widget.productName ?? 'Order tracking',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
            letterSpacing: -0.6,
          ),
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
              onRefresh: _loadStatus,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  if (_statusData == null)
                    _EmptyTrackingState(productName: widget.productName)
                  else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0C3554), Color(0xFF145E8D)],
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 54,
                                width: 54,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  _heroIcon(orderStatus),
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.productName ?? 'Tracked order',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _heroMessage(orderStatus),
                                      style: GoogleFonts.manrope(
                                        fontSize: 13.5,
                                        height: 1.45,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _StatusPill(
                                label: _labelForStatus(orderStatus),
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.16),
                                foregroundColor: Colors.white,
                              ),
                              _StatusPill(
                                label:
                                    'Delivery ${_labelForStatus(deliveryStatus)}',
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.12),
                                foregroundColor: Colors.white70,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    OrderTimeline(currentStatus: orderStatus),
                    const SizedBox(height: 16),
                    Container(
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
                          Text(
                            'Order details',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'The current tracking snapshot for this purchase.',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black.withValues(alpha: 0.62),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _DetailCard(
                                  title: 'Order status',
                                  value: _labelForStatus(orderStatus),
                                  accent: statusColor,
                                  icon: Icons.track_changes_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DetailCard(
                                  title: 'Delivery status',
                                  value: _labelForStatus(deliveryStatus),
                                  accent: _statusColor(deliveryStatus),
                                  icon: Icons.local_shipping_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _DetailCard(
                                  title: 'Payment plan',
                                  value: paymentPlan.replaceAll('_', ' '),
                                  accent: AppTheme.accent,
                                  icon: Icons.account_balance_wallet_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DetailCard(
                                  title: 'Purchase ID',
                                  value: widget.purchaseId.length > 8
                                      ? widget.purchaseId.substring(
                                          widget.purchaseId.length - 8,
                                        )
                                      : widget.purchaseId,
                                  accent: AppTheme.ocean,
                                  icon: Icons.tag_outlined,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFF6D2B0),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: AppTheme.accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'What happens next',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _heroMessage(orderStatus),
                                  style: GoogleFonts.manrope(
                                    fontSize: 12.8,
                                    height: 1.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black.withValues(alpha: 0.64),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: foregroundColor,
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.value,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String value;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.58),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTrackingState extends StatelessWidget {
  const _EmptyTrackingState({required this.productName});

  final String? productName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
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
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.track_changes_rounded,
              size: 32,
              color: AppTheme.ocean,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            productName ?? 'Tracking unavailable',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We could not load the tracking details for this order right now. Pull to refresh and try again.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 13,
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
