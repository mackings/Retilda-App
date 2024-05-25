import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/transactionsmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;

class Transactions extends ConsumerStatefulWidget {
  const Transactions({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TransactionsState();
}

class _TransactionsState extends ConsumerState<Transactions> {
  String? balance;
  String? _token;
  String? wallet;
  List<Content> _transactions = [];

  Future<void> _loadUserData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userDataString = sharedPreferences.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      String token = userData['data']['token'];
      String Wallet = userData['data']['user']['wallet']['accountNumber'];

      setState(() {
        _token = token;
        wallet = Wallet;
      });

      fetchTransactions();
      getWalletBalance(wallet.toString());
    }
  }

  Future<void> fetchTransactions() async {
    final url =
        Uri.parse('https://retilda.onrender.com/Api/transactions/$wallet');

    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    });

    if (response.statusCode == 200) {
      final apiResponse = ApiResponse.fromJson(jsonDecode(response.body));
      setState(() {
        _transactions = apiResponse.data.responseBody.content;
        print("Transactions $_transactions");
      });
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  Future<void> getWalletBalance(String walletAccountNumber) async {
    final Uri url = Uri.parse('https://retilda.onrender.com/Api/balance');

    Map<String, String> requestBody = {
      'walletAccountNumber': wallet.toString(),
    };

    String requestBodyJson = jsonEncode(requestBody);

    try {
      http.Response response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: requestBodyJson,
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = jsonDecode(response.body);

        setState(() {
          balance = responseBody['data']['responseBody']['availableBalance']
              .toString();
        });
      } else {
        print('Failed to fetch wallet balance: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching wallet balance: $error');
    }
  }

  @override
  void initState() {
    _loadUserData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: CustomText(
          "Transactions",
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 3.h,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30, right: 30),
            child: Container(
              height: 20.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: AssetImage("assets/bg.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          "Available Balance",
                          color: Colors.white,
                          fontSize: 8.sp,
                        ),
                        CustomText(
                          'N${balance == null ? "****" : balance.toString()}',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            fetchTransactions();
                          },
                          child: Container(
                            height: 5.h,
                            width: 31.w,
                            decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(8)),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    CustomText(
                                      "Add money",
                                      color: Colors.white,
                                    ),
                                    Icon(Icons.add,color: Colors.white,),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 20,top: 30),
            child: Row(
              children: [
                CustomText("Transaction History",
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                ),
              ],
            ),
          ),
          Expanded(
            child: _transactions.isEmpty
                ? Center(child: Padding(
                  padding: const EdgeInsets.only(left: 30,right: 30),
                  child: LinearProgressIndicator(),
                ))
                : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactions[index];
                        final formattedDate = DateFormat('MMMM d, yyyy, h:mma').format(DateTime.parse(transaction.transactionDate));
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(width: 0.5,color: Colors.grey)
                            ),
                            child: ListTile(
                              leading: transaction.transactionType=="DEBIT"?Icon(Icons.arrow_circle_down_sharp,color: Colors.red,):Icon(Icons.arrow_circle_up_sharp,color: Colors.green,),
                              title: CustomText(transaction.transactionType),
                              subtitle: CustomText(formattedDate),
                              trailing: CustomText('N${transaction.amount}'),
                            ),
                          ),
                        );
                      },
                    ),
                ),
          ),
        ],
      ),
    );
  }
}
