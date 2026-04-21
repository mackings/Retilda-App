import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/OrderTracking/views/order_tracking_screen.dart';
import 'package:retilda/Views/Widgets/paymentscard.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/model/purchases.dart';
import 'package:sizer/sizer.dart';

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
              'Order tracking',
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: deepBlue,
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
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 140),
                              child: Column(
                                children: [
                                  Icon(Icons.track_changes,
                                      size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  CustomText(
                                    'No purchases yet',
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                    color: deepBlue,
                                  ),
                                  const SizedBox(height: 6),
                                  CustomText(
                                    'Track orders once you start buying.',
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
                          itemCount: _purchases.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final purchase = _purchases[index];
                            final DateTime paymentDate;
                            if (purchase.payments != null &&
                                purchase.payments!.isNotEmpty) {
                              final firstPayment = purchase.payments!.first;
                              final String? dateValue =
                                  firstPayment.paymentDate ??
                                      firstPayment.nextPaymentDate;
                              paymentDate = dateValue != null
                                  ? DateTime.parse(dateValue)
                                  : DateTime.now();
                            } else {
                              paymentDate = DateTime.now();
                            }

                            return PaymentSummaryCard(
                              date: paymentDate,
                              imageUrl:
                                  purchase.product?.images?.isNotEmpty == true
                                      ? purchase.product!.images!.first
                                      : '',
                              title: purchase.product?.name ?? 'Purchase',
                              subtitle: purchase.paymentPlan == 'once'
                                  ? 'One time payment of N${NumberFormat('#,##0').format(purchase.payments?.first.amountPaid ?? 0)}'
                                  : 'N${NumberFormat('#,##0').format(purchase.totalAmountPaid ?? 0)} out of N${NumberFormat('#,##0').format(purchase.totalAmountToPay ?? 0)}',
                              trailing: TextButton(
                                onPressed: () {
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
                                child: const Text('Track'),
                              ),
                            );
                          },
                        ),
                ),
        );
      },
    );
  }
}
