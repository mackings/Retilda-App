import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/OrderTracking/api/order_status_service.dart';
import 'package:retilda/Views/OrderTracking/widgets/order_timeline.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/order_status.dart';
import 'package:sizer/sizer.dart';

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
              widget.productName ?? 'Order Tracking',
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
                  onRefresh: _loadStatus,
                  child: ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    children: [
                      OrderTimeline(
                        currentStatus:
                            _statusData?.orderStatus ?? 'processing',
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
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
                            CustomText(
                              'Details',
                              fontWeight: FontWeight.w700,
                              fontSize: 15.sp,
                              color: deepBlue,
                            ),
                            const SizedBox(height: 10),
                            _DetailRow(
                              title: 'Order status',
                              value: _statusData?.orderStatus ?? 'processing',
                            ),
                            _DetailRow(
                              title: 'Delivery status',
                              value: _statusData?.deliveryStatus ?? 'processing',
                            ),
                            _DetailRow(
                              title: 'Payment plan',
                              value: _statusData?.paymentPlan ?? 'monthly',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String title;
  final String value;

  const _DetailRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    const Color deepBlue = Color(0xFF103C57);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            title,
            fontSize: 13.sp,
            color: Colors.grey[600],
          ),
          CustomText(
            value,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: deepBlue,
          ),
        ],
      ),
    );
  }
}
