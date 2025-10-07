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
      if (payments[i].paymentDate == null) {
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
      if (payments[i].paymentDate == null) {
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
      if (payments[i].paymentDate == null) {
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
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(result['message']),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
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
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(result['message']),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showPaymentMethodDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: CustomText(
            'Select Your Payment method',
            fontWeight: FontWeight.w400,
            fontSize: 12.sp,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Pay from Wallet'),
                onTap: () {
                  Navigator.pop(context);
                  _handleWalletPayment();
                },
              ),
              ListTile(
                title: Text('Pay with Card'),
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
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Failed"),
          content: Text(result['message']),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
      );
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
        return Scaffold(
          backgroundColor: Colors.white,
          bottomNavigationBar: BottomAppBar(
            color: Colors.orange,
            height: 50,
            child: InkWell(
              onTap: _handleTopUpForDelivery,
              child: Center(
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : const CustomText(
                        "Top-up for Delivery",
                        color: Colors.white,
                      ),
              ),
            ),
          ),
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: CustomText(
              "Payment summary",
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          body: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Center(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 30, right: 30, top: 20),
                    child: Container(
                      height: 30.h,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(widget.purchase.product!.images![0]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 30, right: 30, top: 20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText(
                              widget.purchase.product!.name.toString(),
                              fontWeight: FontWeight.w600,
                              fontSize: 15.sp,
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Divider(color: Colors.grey),
                        ),
                        if (widget.purchase.totalAmountToPay!.toInt() !=
                            widget.purchase.totalAmountPaid!.toInt())
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _showPaymentMethodDialog,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: RButtoncolor,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 20, right: 20, top: 10, bottom: 10),
                                    child: CustomText(
                                      "Pay Installments",
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Divider(color: Colors.grey),
                        ),
                        LinearCompletionIndicator(
                          totalAmountToPay: widget.purchase.totalAmountToPay!.toInt(),
                          totalAmountPaid: widget.purchase.totalAmountPaid!.toInt(),
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            CustomText(
                              "Payments Breakdown:",
                              fontWeight: FontWeight.w500,
                            ),
                          ],
                        ),
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
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
