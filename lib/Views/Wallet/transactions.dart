import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Wallet/Model/transactions.dart';
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
  String? _token;
  int? WalletBalance;
  String? AccountNumber;
  String? AccountName;
  List<Content> _transactions = [];
  dynamic _userBalance;

  bool _isLoading = true;

  Future<void> _loadUserData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userDataString = sharedPreferences.getString('userData');

    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      print(
          "Parsed User Data: $userData"); // Log entire parsed data for confirmation

      String? token = userData['data']?['token'];
      String? account = userData['data']?['user']?['wallet']?['accountNumber'];
      int? balance = userData['data']?['user']?['balance'];
      String? name = userData['data']?['user']?['wallet']?['accountName'];

      setState(() {
        _token = token;
        AccountNumber = account;
        AccountName = name;
        WalletBalance = balance;
      });


      await fetchTransactions();
      await fetchUserBalance(); 
    }
  }

  Future<void> fetchTransactions() async {
    final url =
        Uri.parse('https://retilda-fintech.vercel.app/Api/viewTransactionHistory');

    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    });

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final List<dynamic> transactionsData = responseData['transactions'];

      setState(() {
        _transactions = transactionsData
            .map((transaction) => Content.fromJson(transaction))
            .toList();
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  Future<void> fetchUserBalance() async {
    final url = Uri.parse('https://retilda-fintech.vercel.app/Api/userBalance');

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      });
 
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          final double userBalance = responseData['data'].toDouble();

          setState(() {
            _userBalance = userBalance;
            _isLoading = false;
          });
          print(_userBalance);
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        print(response.body);
        throw Exception('Failed to load user balance');
      }
    } catch (error) {
      print('Error fetching user balance: $error');
    }
  }

  String formatBalance(double? balance) {
    if (balance == null) return "****";
    return balance.toStringAsFixed(1).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ",",
        );
  }

  void showBankDetailsModal(
      BuildContext context, String bankName, String accountNumber) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      child: Icon(Icons.close, color: Colors.black),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10),

              // Descriptive Text
              Text(
                'Make a bank transfer to the bank account below to top up your wallet.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
              ),
              SizedBox(height: 30),
              Divider(color: Colors.grey.shade300),

              // Bank Name Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bank Name:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    bankName,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Divider(color: Colors.grey.shade300),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Account Number:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        accountNumber,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, size: 16),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: accountNumber));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Account Number Copied')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10),
              Divider(color: Colors.grey.shade300), // Bottom Divider

              SizedBox(height: 10),
              Align(
                alignment: Alignment.center,
                child: Text(
                  'Thank you for choosing Retilda!',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                ),
              ),
            ],
          ),
        );
      },
    );
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
        actions: [
          GestureDetector(
              onTap: () {
                fetchUserBalance();
              },
              child: Icon(Icons.refresh_rounded))
        ],
      ),
      body: Column(
        children: [
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
                          'N${formatBalance(_userBalance)}',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        CustomText(
                          "$AccountNumber",
                          color: Colors.white,
                          fontSize: 10.sp,
                        ),
                        CustomText(
                          "Wema Bank",
                          color: Colors.white,
                          fontSize: 8.sp,
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            showBankDetailsModal(
                                context, "Wema Bank", "$AccountNumber");
                          },
                          child: Container(
                            height: 5.h,
                            width: 30.w,
                            decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(8)),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    CustomText(
                                      "Top Up",
                                      color: Colors.white,
                                      fontSize: 8.sp,
                                    ),
                                    Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 15,
                                    ),
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
            padding: const EdgeInsets.only(left: 20, top: 30),
            child: Row(
              children: [
                CustomText(
                  "Transaction History",
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ],
            ),
          ),
          Expanded(
            child: _transactions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 30, right: 30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline,
                              size: 50, color: Colors.black),
                          SizedBox(height: 16),
                          CustomText(
                            'No transactions available',
                          ),
                        ],
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView.builder(
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        // Reverse the index to display the latest first
                        final transaction =
                            _transactions[_transactions.length - 1 - index];
                        final transactionDateTime =
                            DateTime.parse(transaction.transactionDate)
                                .add(Duration(hours: 1));
                        final formattedDate = DateFormat('MMMM d, yyyy, h:mma')
                            .format(transactionDateTime);

                        final formattedAmount = NumberFormat.currency(
                          locale: 'en_NG',
                          symbol: 'N',
                          decimalDigits: 0,
                        ).format(transaction.amount);

                        // Determine the title based on transaction type
                        final titleText =
                            transaction.transactionType == "purchase"
                                ? (transaction.status == "settlement"
                                    ? "Product Settlement"
                                    : "Product Purchase")
                                : transaction.senderName;

                        return Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(width: 0.5, color: Colors.grey),
                            ),
                            child: ListTile(
                              leading: transaction.transactionType == "purchase"
                                  ? Icon(Icons.arrow_circle_down_sharp,
                                      color: Colors.red)
                                  : Icon(Icons.arrow_circle_up_sharp,
                                      color: Colors.green),
                              title: CustomText(
                                  titleText), // Conditionally set title
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(formattedDate),
                                  CustomText(
                                    transaction.description, // Description
                                    fontSize: 8.sp,
                                  ),
                                ],
                              ),
                              trailing: CustomText(formattedAmount), // Amount
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
