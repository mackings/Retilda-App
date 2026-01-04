import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Products/Connect/views/connect.dart';
import 'package:retilda/Views/Wallet/Api/ApiService.dart';
import 'package:retilda/Views/Widgets/breakdownwidget.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/deliverymodal.dart';
import 'package:retilda/Views/Widgets/linearpercent.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/purchases.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';




class Purchasesummary extends ConsumerStatefulWidget {
  final Purchase purchase;
  const Purchasesummary({super.key, required this.purchase});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PurchasesummaryState();
}

class _PurchasesummaryState extends ConsumerState<Purchasesummary> {
  final WalletApiService _walletService = WalletApiService();

  String? productId;
  String? UserId;
  String? PurchaseId;
  String? Token;
  dynamic Wallet;
  bool _isLoading = false;

  Future<void> _loadUserData() async {
    final userData = await _walletService.getUserData();
    if (userData != null) {
      setState(() {
        Token = userData['token'];
        UserId = userData['userId'];
        PurchaseId = widget.purchase.id;
        productId = widget.purchase.product!.id;
        Wallet = userData['wallet'];
      });

      print("Product ID >> $productId");
      print("Purchase ID >> $PurchaseId");
    }
  }


  String getNextPaymentDate(List<Payment> payments) {
  for (int i = 0; i < payments.length; i++) {
    if (payments[i].status != 'completed') {
      final DateTime nextPaymentDateTime =
          DateTime.parse(payments[i].nextPaymentDate.toString());
      final DateFormat formatter = DateFormat('dd MMM yy');
      return formatter.format(nextPaymentDateTime);
    }
  }
  return "Cleared";
}

String getNextPaymentAmount(List<Payment> payments) {
  for (int i = 0; i < payments.length; i++) {
    if (payments[i].status != 'completed') {
      final amountToPay = payments[i].amountToPay ?? 0;
      final amountPaid = payments[i].amountPaid ?? 0;
      final remainingAmount = amountToPay - amountPaid;
      return 'N${remainingAmount.toStringAsFixed(0)}';
    }
  }
  return "N 0";
}

String getNextPaymentStatus(List<Payment> payments) {
  for (int i = 0; i < payments.length; i++) {
    if (payments[i].status != 'completed') {
      final amountToPay = payments[i].amountToPay ?? 0;
      final amountPaid = payments[i].amountPaid ?? 0;
      
      if (amountPaid > 0 && amountPaid < amountToPay) {
        return 'Partially Paid (N${amountPaid.toStringAsFixed(0)} of N${amountToPay.toStringAsFixed(0)})';
      } else if (amountPaid == 0) {
        return 'Not Paid';
      }
    }
  }
  return "Fully Paid";
}


  Future<void> _handleWalletPayment() async {
    if (productId == null) return;

    setState(() => _isLoading = true);

    final result = await _walletService.makeInstallmentPaymentUsingWallet(productId!);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Success'),
            content: Text(result['message']),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      _showApiDialog(title: 'Error', message: result['message'] ?? 'Payment failed');
    }
  }

  Future<void> _handleCardPayment() async {
    if (productId == null) return;

    setState(() => _isLoading = true);

    final result = await _walletService.makeInstallmentPaymentUsingCard(productId!);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      final String paymentUrl = result['paymentUrl'];
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Card Payment'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: WebViewPage(url: paymentUrl),
          );
        },
      );
    } else {
      _showApiDialog(title: 'Error', message: result['message'] ?? 'Card payment failed');
    }
  }

  void _showPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          title: CustomText(
            'Choose how to pay',
            fontWeight: FontWeight.w700,
            fontSize: 13.sp,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined, color: Colors.green),
                title: const Text('Pay from Wallet'),
                subtitle: const Text('Instant debit from your Retilda wallet'),
                onTap: () {
                  Navigator.pop(context);
                  _handleWalletPayment();
                },
              ),
              ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.blue),
                title: const Text('Pay with Card'),
                subtitle: const Text('Secure card checkout'),
                onTap: () {
                  Navigator.pop(context);
                  _handleCardPayment();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleTopUpForDelivery() async {
    if (_isLoading || productId == null) return;

    setState(() => _isLoading = true);

    final calculation = _walletService.calculateTopUpAmount(
      totalAmount: widget.purchase.totalAmountToPay!.toDouble(),
      amountPaid: widget.purchase.totalAmountPaid!.toDouble(),
    );

    if (!calculation['isValid']) {
      setState(() => _isLoading = false);
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("No Top-up Needed"),
          content: Text(calculation['message']),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    final result = await _walletService.topUpWalletForDelivery(
      productId!,
      calculation['amountToTopUp'],
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Top-up Successful"),
          content: const Text("You can now request for Delivery"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      _showApiDialog(title: "Failed", message: result['message'] ?? 'Top-up failed');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    Timer(Duration(seconds: 1), () {
      if (widget.purchase.totalAmountPaid! >=
          widget.purchase.totalAmountToPay! * 0.6) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => DeliveryModal(
            purchaseId: '${widget.purchase.id}',
          ),
        );
      }
    });
  }

  Future<void> _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session expired. Please sign in again.')),
    );
  }

  void _showApiDialog({
    required String title,
    required String message,
  }) {
    final lower = message.toLowerCase();
    final bool tokenExpired =
        lower.contains('token has expired') || lower.contains('401');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          tokenExpired ? "Session expired" : title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          tokenExpired
              ? "Your session has expired. Please log out and sign back in to continue."
              : message,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
          if (tokenExpired)
            TextButton(
              onPressed: _forceLogout,
              child: const Text("Log out"),
            ),
        ],
      ),
    );
    if (tokenExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please sign in again.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedAmount = NumberFormat.currency(
      locale: 'en_NG',
      symbol: 'N',
      decimalDigits: 0,
    ).format(widget.purchase.totalAmountToPay);

    final formattedAmount2 = NumberFormat.currency(
      locale: 'en_NG',
      symbol: 'N',
      decimalDigits: 0,
    ).format(widget.purchase.totalAmountPaid);

    return Sizer(
      builder: (context, orientation, deviceType) {
        const Color pageBg = Color(0xFFF6F7FB);
        const Color deepBlue = Color(0xFF103C57);
        const Color accent = Color(0xFFFB9324);

        return Scaffold(
          backgroundColor: pageBg,
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleTopUpForDelivery,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shadowColor: Colors.orange.withOpacity(0.3),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const CustomText(
                          "Top-up for Delivery",
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                ),
              ),
            ),
          ),
          appBar: AppBar(
            backgroundColor: pageBg,
            title: CustomText(
              "Payment summary",
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: deepBlue,
            ),
          ),
          body: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Container(
                    height: 28.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            widget.purchase.product!.images![0],
                            fit: BoxFit.cover,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.45),
                                  Colors.transparent
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.storefront_outlined,
                                      size: 16, color: Colors.black87),
                                  const SizedBox(width: 6),
                                  CustomText(
                                    widget.purchase.paymentPlan ?? "Plan",
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: CustomText(
                                widget.purchase.product!.name.toString(),
                                fontWeight: FontWeight.w700,
                                fontSize: 15.sp,
                                color: deepBlue,
                              ),
                            ),
                            // if (widget.purchase.totalAmountToPay!.toInt() !=
                            //     widget.purchase.totalAmountPaid!.toInt())
                            //   GestureDetector(
                            //     onTap: _showPaymentMethodDialog,
                            //     child: Container(
                            //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            //       decoration: BoxDecoration(
                            //         color: RButtoncolor,
                            //         borderRadius: BorderRadius.circular(12),
                            //       ),
                            //       child: CustomText(
                            //         "Pay Installments",
                            //         fontWeight: FontWeight.w600,
                            //         fontSize: 11.sp,
                            //         color: Colors.white,
                            //       ),
                            //     ),
                            //   ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: deepBlue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 14, color: deepBlue),
                                  const SizedBox(width: 6),
                                  CustomText(
                                    "Next: ${getNextPaymentDate(widget.purchase.payments!.toList())}",
                                    fontSize: 11.sp,
                                    color: deepBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearCompletionIndicator(
                          totalAmountToPay: widget.purchase.totalAmountToPay!.toInt(),
                          totalAmountPaid: widget.purchase.totalAmountPaid!.toInt(),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                "Payment methods",
                                fontWeight: FontWeight.w700,
                                fontSize: 12.sp,
                                color: deepBlue,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _showPaymentMethodDialog,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: accent,
                                        elevation: 0,
                                        side: BorderSide(color: accent),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: CustomText(
                                        "Pay Installments",
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.sp,
                                        color: accent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _handleCardPayment,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: deepBlue,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: CustomText(
                                        "One-time card",
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          "Payments Breakdown",
                          fontWeight: FontWeight.w700,
                          fontSize: 13.sp,
                          color: deepBlue,
                        ),
                        const SizedBox(height: 8),
                        PaymentBreakdownWidget(
                          title: 'Total Amount:',
                          amount: formattedAmount,
                          index: null,
                        ),
                        PaymentBreakdownWidget(
                          title: 'Total Amount Paid:',
                          amount: formattedAmount2,
                          index: null,
                        ),
                        PaymentBreakdownWidget(
                          title: 'Payment Plan:',
                          amount: '${widget.purchase.paymentPlan}',
                          index: null,
                        ),
                        PaymentBreakdownWidget(
                          title: 'Payment Duration:',
                          amount:
                              '${widget.purchase.payments!.length} ${widget.purchase.paymentPlan == "monthly" ? 'Months' : "weeks"}',
                          index: null,
                        ),
                        PaymentBreakdownWidget(
                          title: 'Next payment Date:',
                          amount: getNextPaymentDate(widget.purchase.payments!.toList()),
                          index: 0,
                        ),
                        PaymentBreakdownWidget(
                          title: 'Next payment Amount:',
                          amount: getNextPaymentAmount(widget.purchase.payments!),
                          index: 0,
                        ),
                        PaymentBreakdownWidget(
                          title: 'Shipping Status:',
                          amount: widget.purchase.deliveryStatus.toString(),
                          index: 0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 100), // ensure bottom CTA visible
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
