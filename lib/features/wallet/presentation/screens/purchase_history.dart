import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Wallet/purchasesummary.dart';
import 'package:retilda/Views/Reviews/views/reviews_screen.dart';
import 'package:retilda/Views/Widgets/paymentscard.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/model/purchases.dart';
import 'package:sizer/sizer.dart';

class PurchaseHistory extends ConsumerStatefulWidget {
  const PurchaseHistory({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PurchaseHistoryState();
}

class _PurchaseHistoryState extends ConsumerState<PurchaseHistory> {
  late final AppSession _session = AppSession();
  late final ApiClient _apiClient = ApiClient(session: _session);
  List<Purchase> _purchases = [];

  String? _token;
  String? _userId;
  bool _isLoading = true;

  Future<PurchaseResponse> fetchPurchases(String userId, String token) async {
    final response = await _apiClient.get('getAllPendingPurchases');

    if (response.statusCode == 200) {
      return PurchaseResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load purchases');
    }
  }

  Future<void> _refreshPurchases() async {
    if (_token != null && _userId != null) {
      try {
        final apiResponse = await fetchPurchases(_userId!, _token!);
        setState(() {
          _purchases = apiResponse.data!.purchasesData!;
        });
      } catch (error) {}
    }
  }

  Future<void> _loadUserData() async {
    final userData = await _session.userData();
    final token = await _session.userToken();
    if (userData != null && token != null) {
      String userId = userData['data']['user']['_id'];
      setState(() {
        _token = token;
        _userId = userId;
      });

      fetchPurchases(userId, token).then((apiResponse) {
        setState(() {
          _purchases = apiResponse.data!.purchasesData!;
          _isLoading = false;
        });
      }).catchError((error) {
        setState(() {
          _isLoading = false;
        });
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
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
            automaticallyImplyLeading: false,
            title: CustomText(
              "Purchase history",
              fontSize: 17.sp,
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
                  onRefresh: _refreshPurchases,
                  child: _purchases.isEmpty
                      ? ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 140),
                              child: Column(
                                children: [
                                  Icon(Icons.receipt_long,
                                      size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  CustomText(
                                    "No purchases yet",
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: deepBlue,
                                  ),
                                  const SizedBox(height: 6),
                                  CustomText(
                                    "Your purchases will appear here once you start buying.",
                                    fontSize: 11.sp,
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

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        Purchasesummary(purchase: purchase),
                                  ),
                                );
                              },
                              child: PaymentSummaryCard(
                                date: paymentDate,
                                imageUrl: purchase.product!.images![0],
                                title: purchase.product!.name.toString(),
                                subtitle: purchase.paymentPlan == "once"
                                    ? "One time payment of N${NumberFormat('#,##0').format(purchase.payments?.first.amountPaid ?? 0)}"
                                    : "N${NumberFormat('#,##0').format(purchase.totalAmountPaid ?? 0)} out of N${NumberFormat('#,##0').format(purchase.totalAmountToPay ?? 0)}",
                                trailing: TextButton(
                                  onPressed: purchase.hasPaidDownPayment
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ReviewsScreen(
                                                productId:
                                                    purchase.product?.id ?? '',
                                                productName:
                                                    purchase.product?.name,
                                              ),
                                            ),
                                          );
                                        }
                                      : null,
                                  child: Text(
                                    purchase.hasPaidDownPayment
                                        ? 'Review'
                                        : 'Pay deposit',
                                  ),
                                ),
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
