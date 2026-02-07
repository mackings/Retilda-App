import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  num? WalletBalance;
  String? AccountNumber;
  String? AccountName;
  List<Content> _transactions = [];
  dynamic _userBalance;
  String _typeFilter = 'all'; // all, debit, credit

  bool _isLoading = true;

  Map<String, String>? _redactHeaders(Map<String, String>? headers) {
    if (headers == null) return null;
    final redacted = Map<String, String>.from(headers);
    if (redacted.containsKey('Authorization')) {
      redacted['Authorization'] = 'Bearer ***';
    }
    return redacted;
  }

  void _logApi({
    required String label,
    required Uri url,
    Map<String, String>? headers,
    Object? payload,
    http.Response? response,
    Object? error,
  }) {
    final safeHeaders = _redactHeaders(headers);
    final buffer = StringBuffer()
      ..writeln('[$label]')
      ..writeln('URL: $url');
    if (payload != null) {
      buffer.writeln('Payload: $payload');
    } else {
      buffer.writeln('Payload: <none>');
    }
    if (safeHeaders != null) {
      buffer.writeln('Headers: $safeHeaders');
    }
    if (response != null) {
      buffer
        ..writeln('Status: ${response.statusCode}')
        ..writeln('Response: ${response.body}');
    }
    if (error != null) {
      buffer.writeln('Error: $error');
    }
    debugPrint(buffer.toString());
  }

  Future<void> _loadUserData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userDataString = sharedPreferences.getString('userData');

    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      print(
          "Parsed User Data: $userData"); // Log entire parsed data for confirmation

      String? token = userData['data']?['token'];
      String? account = userData['data']?['user']?['wallet']?['accountNumber'];
      num balance = userData['data']?['user']?['balance'];
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
    final url = Uri.parse(
        'https://retildaserver.vercel.app/Api/viewTransactionHistory');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };

    _logApi(
      label: 'GET viewTransactionHistory',
      url: url,
      headers: headers,
    );

    final response = await http.get(url, headers: headers);

    _logApi(
      label: 'GET viewTransactionHistory',
      url: url,
      headers: headers,
      response: response,
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final List<dynamic> transactionsData = responseData['transactions'];
      debugPrint('Transactions count: ${transactionsData.length}');

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
    final url =
        Uri.parse('https://retildaserver.vercel.app/Api/userBalance');

    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };

      _logApi(
        label: 'GET userBalance',
        url: url,
        headers: headers,
      );

      final response = await http.get(url, headers: headers);

      _logApi(
        label: 'GET userBalance',
        url: url,
        headers: headers,
        response: response,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          final double userBalance = responseData['data'].toDouble();

          setState(() {
            _userBalance = userBalance;
            _isLoading = false;
          });
          debugPrint('User balance: $_userBalance');
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception('Failed to load user balance');
      }
    } catch (error) {
      _logApi(
        label: 'GET userBalance',
        url: url,
        error: error,
      );
    }
  }

  String formatBalance(double? balance) {
    if (balance == null) return "****";
    return balance.toStringAsFixed(1).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ",",
        );
  }

  List<Content> get _filteredTransactions {
    if (_typeFilter == 'all') return _transactions;
    final bool wantDebit = _typeFilter == 'debit';
    return _transactions
        .where((t) => (t.transactionType == "purchase") == wantDebit)
        .toList();
  }

  void showBankDetailsModal(
      BuildContext context, String bankName, String accountNumber) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          minChildSize: 0.25,
          initialChildSize: 0.35,
          maxChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        "Wallet top-up",
                        fontWeight: FontWeight.w900,
                        fontSize: 15.sp,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey.shade200,
                          child: const Icon(Icons.close, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CustomText(
                    'Send a transfer to fund your wallet.',
                    fontSize: 13.sp,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4C75).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText(
                              'Bank',
                              fontSize: 12.sp,
                              color: Colors.grey[700],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F4C75).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: CustomText(
                                bankName,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F4C75),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  'Account Number',
                                  fontSize: 12.sp,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(height: 6),
                                CustomText(
                                  accountNumber,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 22),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: accountNumber));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Account Number Copied')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  CustomText(
                    'Funds reflect automatically once your transfer clears.',
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            );
          },
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
    const Color pageBg = Color(0xFFF6F7FB);
    const Color deepBlue = Color(0xFF103C57);
    const Color accent = Color(0xFFFB9324);

    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: pageBg,
            title: CustomText(
              "Transactions",
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: deepBlue,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
                onPressed: fetchUserBalance,
              )
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 18.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0C3554), Color(0xFF145E8D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 12),
                      )
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              "Available Balance",
                              color: Colors.white70,
                              fontSize: 12.sp,
                            ),
                            CustomText(
                              'N${formatBalance(_userBalance)}',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            CustomText(
                              "$AccountNumber",
                              color: Colors.white,
                              fontSize: 12.sp,
                            ),
                            CustomText(
                              "Wema Bank",
                              color: Colors.white70,
                              fontSize: 11.sp,
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
                                  color: accent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CustomText(
                                      "Top Up",
                                      color: Colors.white,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.add,
                                        color: Colors.white, size: 16),
                                  ],
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
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                CustomText(
                  "Transaction History",
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: deepBlue,
                ),
              ],
            ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text("All"),
                      selected: _typeFilter == 'all',
                      onSelected: (_) => setState(() => _typeFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text("Debit"),
                      selected: _typeFilter == 'debit',
                      onSelected: (_) => setState(() => _typeFilter = 'debit'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text("Credit"),
                      selected: _typeFilter == 'credit',
                      onSelected: (_) => setState(() => _typeFilter = 'credit'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: LinearProgressIndicator(color: accent, minHeight: 4),
                        ),
                      )
                    : _transactions.isEmpty
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
                                      "No transactions available",
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                      color: deepBlue,
                                    ),
                                    const SizedBox(height: 6),
                                    CustomText(
                                      "Your transactions will appear here once you start paying.",
                                      fontSize: 13.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: ListView.separated(
                              itemCount: _filteredTransactions.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final transaction =
                                    _filteredTransactions[_filteredTransactions.length - 1 - index];
                                final transactionDateTime =
                                    DateTime.parse(transaction.transactionDate.toString())
                                        .add(const Duration(hours: 1));
                                final formattedDate =
                                    DateFormat('MMMM d, yyyy, h:mma')
                                        .format(transactionDateTime);
                                final formattedAmount = NumberFormat.currency(
                                  locale: 'en_NG',
                                  symbol: 'N',
                                  decimalDigits: 0,
                                ).format(transaction.amount);

                                final bool isDebit =
                                    transaction.transactionType == "purchase";
                                final String titleText =
                                    transaction.transactionType == "purchase"
                                        ? (transaction.status == "settlement"
                                            ? "Product Settlement"
                                            : "Product Purchase")
                                        : (transaction.senderName == "Unknown Sender"
                                            ? "Service charge"
                                            : transaction.senderName);

                                final bool success =
                                    (transaction.status).toLowerCase() == 'success';

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 8),
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: isDebit
                                                  ? Colors.red.withOpacity(0.1)
                                                  : Colors.green.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              isDebit
                                                  ? Icons.south_east
                                                  : Icons.north_east,
                                              color:
                                                  isDebit ? Colors.red : Colors.green,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                      SizedBox(
                                    width: 170,
                                    child: CustomText(
                                      titleText,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w800,
                                      color: deepBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 170,
                                    child: CustomText(
                                      transaction.description,
                                      fontSize: 14.sp,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  CustomText(
                                    formattedDate,
                                    fontSize: 13.sp,
                                    color: Colors.grey[600],
                                  ),
                                ],
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                  CustomText(
                                    formattedAmount,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w900,
                                    color: isDebit ? Colors.red : Colors.green,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                            decoration: BoxDecoration(
                                              color: success
                                                  ? Colors.green.withOpacity(0.1)
                                                  : Colors.orange.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                    child: CustomText(
                                      transaction.status,
                                      fontSize: 13.sp,
                                      color: success
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
