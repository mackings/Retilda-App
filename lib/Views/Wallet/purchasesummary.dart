import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Widgets/breakdownwidget.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/deliverymodal.dart';
import 'package:retilda/Views/Widgets/linearpercent.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/purchases.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class Purchasesummary extends ConsumerStatefulWidget {
  final Purchase purchase;
  const Purchasesummary({super.key, required this.purchase});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PurchasesummaryState();
}

class _PurchasesummaryState extends ConsumerState<Purchasesummary> {
  String? productId;
  String? UserId;
  String? PurchaseId;
  String? Token;
  String? UserOptions;
  dynamic Wallet;
  String? balance;
  bool? loading;

  Future<void> makeInstallmentPaymentRequest(
      BuildContext context, String productId, String token) async {
    Map<String, String> requestBody = {
      "productId": productId,
    };

    String requestBodyJson = jsonEncode(requestBody);

    try {
      print("Payload >> $requestBodyJson");
      http.Response response = await http.post(
        Uri.parse(
            'https://retilda-fintech.onrender.com/Api/installmentRepaymentUsingWallet'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Use the provided token
        },
        body: requestBodyJson,
      );

      if (response.statusCode == 200) {
        print('Installment payment request successful');
        print('Response: ${response.body}');

        // Ensure the context is still valid
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Success'),
                content: Text('Payment successful!'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Error'),
                content: Text('Payment Error, kindly retry'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        }
        print(response.body);
        print(
            'Installment payment request failed with status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error making installment payment request: $error');
    }
  }

  Future<void> installmentRepaymentUsingCard(
      BuildContext context, String productId) async {
    const String url =
        'https://retilda-fintech.onrender.com/Api/installmentRepaymentUsingCard';

    final Map<String, String> requestBody = {
      'productId': productId,
    };

    try {
      // Make the POST request
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $Token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true &&
            responseData['data'] != null &&
            responseData['data']['paymentUrl'] != null) {
          final String paymentUrl = responseData['data']['paymentUrl'];
          print('Payment URL: $paymentUrl');

          // Show the WebView in an overlay
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Card Payment'),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the overlay
                    },
                  ),
                ),
                body: WebView(
                  initialUrl: paymentUrl,
                  javascriptMode: JavascriptMode.unrestricted,
                ),
              );
            },
          );
        } else {
          print('Invalid response data: ${response.body}');
        }
      } else {
        print('Error: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }
    } catch (error) {
      print('Exception occurred: $error');
    }
  }

  Future<void> _loadUserData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userDataString = sharedPreferences.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      String token = userData['data']['token'];
      String userId = userData['data']['user']['_id'];
      String wallet = userData['data']['user']['wallet']['accountNumber'];

      setState(() {
        Token = token;
        UserId = userId;
        PurchaseId = widget.purchase.id;
        productId = widget.purchase.product!.id;
        Wallet = wallet;
      });

      print("Product ID >> $productId");
      print("Purchase ID >> $PurchaseId");
      print("Purchase ${widget.purchase.id}");
    }
  }

  late final int index = 0;
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
        return 'N${payments[i].amountToPay}';
      }
    }
    return "N 0";
  }

  bool _showPaymentOptions = false;

  void _togglePaymentOptionsVisibility() {
    setState(() {
      _showPaymentOptions = !_showPaymentOptions;
    });
  }

  void _handlePaymentOptionSelected(String option) {
    if (option == 'wallet') {
      makeInstallmentPaymentRequest(context, productId!, Token!);
    } else {
      //installmentRepaymentUsingCard(productId!);
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
              // Wallet payment option
              ListTile(
                title: Text('Pay from Wallet'),
                onTap: () {
                  Navigator.pop(context);
                  _handlePaymentOptionSelected('wallet');
                },
              ),
              ListTile(
                title: Text('Pay with Card'),
                onTap: () {
                  if (productId != null) {
                    installmentRepaymentUsingCard(context, productId!);
                  } else {
                    print("Error: productId is null");
                  }
                },
              )
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
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

    _loadUserData();
    super.initState();
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
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: GestureDetector(
              onTap: () {
                print(widget.purchase.product!.images.toString());
                print(widget.purchase.product!.toJson());
              },
              child: CustomText(
                "Purchase summary",
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          body: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Center(
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 30, right: 30, top: 20),
                    child: Container(
                      height: 30.h,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image:
                              NetworkImage(widget.purchase.product!.images![0]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 30, right: 30, top: 20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText(
                              widget.purchase.product!.name.toString(),
                              fontWeight: FontWeight.w600,
                              fontSize: 11.sp,
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Divider(
                            color: Colors.grey,
                          ),
                        ),
                        if (widget.purchase.totalAmountToPay!.toInt() !=
                            widget.purchase.totalAmountPaid!.toInt())
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    PurchaseId = widget.purchase.id;
                                    productId = widget.purchase.product!.id;
                                    print(productId);
                                  });

                                  _showPaymentMethodDialog();
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: RButtoncolor,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 20,
                                        right: 20,
                                        top: 10,
                                        bottom: 10),
                                    child: CustomText(
                                      "Pay Installments",
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Divider(
                            color: Colors.grey,
                          ),
                        ),
                        LinearCompletionIndicator(
                          totalAmountToPay:
                              widget.purchase.totalAmountToPay!.toInt(),
                          totalAmountPaid:
                              widget.purchase.totalAmountPaid!.toInt(),
                        ),
                        SizedBox(
                          height: 2.h,
                        ),
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
                          amount: getNextPaymentDate(
                              widget.purchase.payments!.toList()),
                          index: index,
                        ),
                        PaymentBreakdownWidget(
                          title: 'Next payment Amount:',
                          amount:
                              getNextPaymentAmount(widget.purchase.payments!),
                          index: index,
                        ),
                        PaymentBreakdownWidget(
                          title: 'Shipping Status:',
                          amount: widget.purchase.deliveryStatus.toString(),
                          index: index,
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

class PaymentOptionsDialog extends StatelessWidget {
  final Function(String) onOptionSelected;

  const PaymentOptionsDialog({
    Key? key,
    required this.onOptionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: CustomText('Select Payment method'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('Option 1'),
            onTap: () => onOptionSelected('Option 1'),
          ),
          ListTile(
            title: Text('Option 2'),
            onTap: () => onOptionSelected('Option 2'),
          ),
          // Add more ListTile widgets for additional payment options
        ],
      ),
    );
  }
}
