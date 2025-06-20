import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Wallet/purchasesummary.dart';
import 'package:retilda/Views/Widgets/paymentscard.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/purchases.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;



class PurchaseHistory extends ConsumerStatefulWidget {
  const PurchaseHistory({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PurchaseHistoryState();
}

class _PurchaseHistoryState extends ConsumerState<PurchaseHistory> {
  List<Purchase> _purchases = [];

  String? _token;
  String? _userId;
  bool _isLoading = true;

  Future<PurchaseResponse> fetchPurchases(String userId, String token) async {
    final url = 'https://retilda-fintech-3jy7.onrender.com/Api/getAllPendingPurchases';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      print(response.body);
      return PurchaseResponse.fromJson(jsonDecode(response.body));
    } else {
      print(response.body);
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
    } catch (error) {
      print('Error refreshing purchases: $error');
    }  
  }
}


  Future<void> _loadUserData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userDataString = sharedPreferences.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      String token = userData['data']['token'];
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
        print('Error fetching purchases: $error');
        setState(() {
          _isLoading = false;
        });
      });


      print("User >>> $userData");

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
    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            automaticallyImplyLeading: false,
            title: CustomText(
              "Purchase history",
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
body: _isLoading
    ? Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: LinearProgressIndicator(),
        ),
      )
    : RefreshIndicator(
        onRefresh: _refreshPurchases,
        child: _purchases.isEmpty
            ? ListView( // Important: Use ListView so RefreshIndicator works even with empty list
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 300),
                      child: CustomText(
                        "You have no purchases.",
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                itemCount: _purchases.length,
                itemBuilder: (context, index) {
                  final purchase = _purchases[index];
                  final DateTime paymentDate =
                      purchase.payments!.isNotEmpty
                          ? DateTime.parse(
                              purchase.payments!.first.paymentDate.toString())
                          : DateTime.now();

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
                          ? "One time payment of N${NumberFormat('#,##0').format(purchase.payments!.first.amountPaid)}"
                          : "N${NumberFormat('#,##0').format(purchase.totalAmountPaid)} out of N${NumberFormat('#,##0').format(purchase.totalAmountToPay)}",
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
