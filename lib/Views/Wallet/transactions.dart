import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
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
        print("Wallet >>> $wallet");
      });
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

  @override
  void initState() {
    _loadUserData();
    Timer(Duration(seconds: 1), () {
      getWalletBalance(wallet.toString());
    });
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
                      image: AssetImage("assets/bg.jpg"), fit: BoxFit.cover)),
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
                          'N${balance== null?"****":balance.toString()}',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 5.h,
                          width: 30.w,
                          decoration: BoxDecoration(
                            color: ROrange,
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Center(child: CustomText("Add money",color: Colors.white,)),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
