import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Widgets/breakdownwidget.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/deliverymodal.dart';
import 'package:retilda/Views/Widgets/linearpercent.dart';
import 'package:retilda/Views/Widgets/paymnetbutton.dart';
import 'package:retilda/Views/Widgets/walletmodal.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/purchases.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;

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
      String userId, String purchaseId, String productId) async {
    Map<String, String> requestBody = {
      "userId": userId,
      "purchaseId": purchaseId,
      "productId": productId,
    };

    String requestBodyJson = jsonEncode(requestBody);

    try {
      print("Payload >> $requestBodyJson");
      http.Response response = await http.post(
        Uri.parse('https://retilda.onrender.com/Api/purchases/installment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $Token',
        },
        body: requestBodyJson,
      );

      if (response.statusCode == 200) {
        print('Installment payment request successful');
        print('Response: ${response.body}');
        // Show success dialog
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
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        print(response.body);
        print(
            'Installment payment request failed with status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error making installment payment request: $error');
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
        productId = widget.purchase.product.id;
        Wallet = wallet;
      });

      getWalletBalance(wallet);

      print("User >>> $userData");
      print("User Token >> $Token");
      print("User ID>> $UserId");
      print("Product ID >> $productId");
      print("Purchase ID >> $PurchaseId");
      print("Account Number >> $wallet ");
    }
  }

  late final int index = 0;
  String getNextPaymentDate(List<Payment> payments) {
    for (int i = 0; i < payments.length; i++) {
      if (payments[i].paymentDate == "Not paid") {
        final DateTime nextPaymentDateTime =
            DateTime.parse(payments[i].nextPaymentDate);
        final DateFormat formatter = DateFormat('dd MMM yy');
        return formatter.format(nextPaymentDateTime);
      }
    }
    return "Cleared";
  }

  String getNextPaymentAmount(List<Payment> payments) {
    for (int i = 0; i < payments.length; i++) {
      if (payments[i].paymentDate == "Not paid") {
        return 'N${payments[i].amountToPay}';
      }
    }
    return "N 0";
  }

  Future<void> getWalletBalance(String walletAccountNumber) async {
    final Uri url = Uri.parse('https://retilda.onrender.com/Api/balance');

    Map<String, String> requestBody = {
      'walletAccountNumber': Wallet,
    };

    String requestBodyJson = jsonEncode(requestBody);

    try {
      http.Response response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $Token',
        },
        body: requestBodyJson,
      );

      if (response.statusCode == 200) {
        print(response.body);
        Map<String, dynamic> responseBody = jsonDecode(response.body);

        print(
            'Wallet balance: ${responseBody['data']['responseBody']['availableBalance']}');

        setState(() {
          balance = responseBody['data']['responseBody']['availableBalance']
              .toString();
        });
      } else {
        print(response.body);
        print('Failed to fetch wallet balance: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching wallet balance: $error');
    }
  }

  bool _showPaymentOptions = false;

  void _togglePaymentOptionsVisibility() {
    setState(() {
      _showPaymentOptions = !_showPaymentOptions;
    });
  }

  void _handlePaymentOptionSelected(String option) {
    print('Payment option selected: $option');
    Navigator.pop(context);
    if (option == 'wallet') {
      print("User selected $option");

      showModalBottomSheet(
        context: context,
        isDismissible: false,
        builder: (BuildContext context) {
          return WalletPaymentModalSheet(
            walletBalance: '',
            // walletBalance: 'N${balance}',
            paymentOptions: ['Installment', 'Full Payment'],
            onPaymentOptionSelected: (selectedOption) {
              print('Selected payment option: $selectedOption');
              setState(() {
                UserOptions = selectedOption;
              });
            },
            isButtonEnabled: true,
            buttonWidgetBuilder: () {
              return PaymentButton(
                onPressed: () async {
                  if (UserOptions == "Installment") {
                    print("installment");
                    await makeInstallmentPaymentRequest(
                        UserId!, PurchaseId!, productId!);
                  } else {
                    print("Full payment");
                  }
                },
                buttonText: 'Make Payment',
              );
            },
          );
        },
      );
    } else {
      // Handle other payment options
    }
  }

  @override
  void initState() {
    Timer(Duration(seconds: 1), () {
          if (widget.purchase.totalAmountToPay == widget.purchase.totalPaidForPurchase) {
           showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => DeliveryModal(),
              );
      
    } else {
       
          
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
    ).format(widget.purchase.totalPaidForPurchase);

    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: GestureDetector(
              onTap: () {
                print(widget.purchase.product.images.toString());
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
                          image: NetworkImage(widget.purchase.product.images),
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
                              widget.purchase.product.name,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.sp,
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  PurchaseId = widget.purchase.id;
                                  productId = widget.purchase.product.id;
                                });
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Builder(
                                      builder: (context) {
                                        return AlertDialog(
                                          title: CustomText(
                                            'Select Payment method',
                                            fontWeight: FontWeight.w400,
                                            fontSize: 12.sp,
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ListTile(
                                                title: Text('Wallet'),
                                                onTap: () =>
                                                    _handlePaymentOptionSelected(
                                                        'wallet'),
                                              ),
                                              ListTile(
                                                title: Text('Card payment'),
                                                onTap: () =>
                                                    _handlePaymentOptionSelected(
                                                        'card'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                              child: Row(
                                children: [
                                  CustomText(
                                    "Pay Installments",
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11.sp,
                                  ),
                                  Icon(Icons.payment),
                                  if (_showPaymentOptions) // Show payment options if _showPaymentOptions is true
                                    PaymentOptionsDialog(
                                      onOptionSelected:
                                          _handlePaymentOptionSelected,
                                    ),
                                ],
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
                              widget.purchase.totalAmountToPay.toInt(),
                          totalAmountPaid:
                              widget.purchase.totalPaidForPurchase.toInt(),
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
                              '${widget.purchase.payments.length} ${widget.purchase.paymentPlan == "monthly" ? 'Months' : "weeks"}',
                          index: null,
                        ),
                        PaymentBreakdownWidget(
                          title: 'Next payment Date:',
                          amount: getNextPaymentDate(widget.purchase.payments),
                          index: index,
                        ),
                        PaymentBreakdownWidget(
                          title: 'Next payment Amount:',
                          amount:
                              getNextPaymentAmount(widget.purchase.payments),
                          index: index,
                        ),
                        PaymentBreakdownWidget(
                          title: 'Shipping Status:',
                          amount: widget.purchase.deliveryStatus,
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
