import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';

class ConnectAccount extends StatefulWidget {
  const ConnectAccount({super.key});

  @override
  State<ConnectAccount> createState() => _ConnectAccountState();
}

class _ConnectAccountState extends State<ConnectAccount> {
  String? token;

  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();

  String? _selectedBank;
  String? _selectedBankCode;
  bool _isLoading = false;

  // Map of bank names and codes
  final Map<String, String> bankCodes = {
    "Abbey Mortgage Bank": "801",
    "Above Only MFB": "51226",
    "Access Bank": "044",
    "Access": "044",
    "Access Bank (Diamond)": "063",
    "ALAT by WEMA": "035A",
    "Amju Unique MFB": "50926",
    "ASO Savings and Loans": "401",
    "Bainescredit MFB": "51229",
    "Bowen Microfinance Bank": "50931",
    "Carbon": "565",
    "Chipper cash": "120001",
    "9 payment service": "120001",
    "CEMCS Microfinance Bank": "50823",
    "Citibank Nigeria": "023",
    "Coronation Merchant Bank": "559",
    "Ecobank Nigeria": "050",
    "Ekondo Microfinance Bank": "562",
    "Eyowo": "50126",
    "Fidelity Bank": "070",
    "Firmus MFB": "51314",
    "First Bank of Nigeria": "011",
    "First Bank": "011",
    "First City Monument Bank": "214",
    "FCMB": "214",
    "FSDH Merchant Bank Limited": "501",
    "Globus Bank": "00103",
    "GoMoney": "100022",
    "Guaranty Trust Bank": "058",
    "GT Bank": "058",
    "GT": "058",
    "Hackman Microfinance Bank": "51233",
    "Hasal Microfinance Bank": "50383",
    "Heritage Bank": "030",
    "Ibile Microfinance Bank": "51244",
    "Infinity MFB": "50457",
    "Jaiz Bank": "301",
    "Kadpoly MFB": "50502",
    "Keystone Bank": "082",
    "Kredi Money MFB LTD": "50211",
    "Kuda Bank": "50211",
    "Kuda": "50211",
    "Lagos Building Investment Company Plc.": "90052",
    "Links MFB": "50549",
    "Lotus Bank": "303",
    "Mayfair MFB": "50563",
    "Moniepoint MFB": "50515",
    "Moniepoint": "50515",
    "Monie point": "50515",
    "Moni point": "50515",
    "Mint MFB": "50212",
    "Paga": "100002",
    "PalmPay": "999991",
    "Palm Pay": "999991",
    "Parallex Bank": "526",
    "Parkway - ReadyCash": "311",
    "Opay": "999992",
    "Petra Microfinance Bank Plc": "50746",
    "Polaris Bank": "076",
    "Providus Bank": "101",
    "QuickFund MFB": "51268",
    "Rand Merchant Bank": "502",
    "Rubies MFB": "51318",
    "Sparkle Microfinance Bank": "51320",
    "Stanbic IBTC Bank": "221",
    "Stanbic IBTC": "221",
    "Standard Chartered Bank": "068",
    "Sterling Bank": "232",
    "Suntrust Bank": "100",
    "TAJ Bank": "302",
    "Tangerine Money": "51269",
    "TCF MFB": "51211",
    "Titan Bank": "102",
    "Unical MFB": "50855",
    "Union Bank of Nigeria": "032",
    "Union Bank": "032",
    "United Bank For Africa": "033",
    "UBA": "033",
    "Unity Bank": "215",
    "VFD Microfinance Bank Limited": "566",
    "VFD": "566",
    "Wema Bank": "035",
    "Zenith Bank": "057",
    "Zenith": "057"
  };

  Future<void> _loadUserData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userDataString = sharedPreferences.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      String Token = userData['data']['token'];

      setState(() {
        token = Token;
        print(token);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_accountNumberController.text.isEmpty ||
        _selectedBank == null ||
        _stateController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _streetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url =
        Uri.parse('https://retilda-fintech-3jy7.onrender.com/Api/direct-debit');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'account': {
          'number': _accountNumberController.text,
          'bank_code': _selectedBankCode,
        },
        'address': {
          'state': _stateController.text,
          'city': _cityController.text,
          'street': _streetController.text,
        }
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(response.body);
      if (data['status'] == 'success' && data['data']['status'] == true) {
        final redirectUrl = data['data']['data']['redirect_url'];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebViewPage(url: redirectUrl),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize authorization')),
        );
      }
    } else {
      print(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
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
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: Text(
        'Connect',
        style: GoogleFonts.poppins(),
      )),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Bank Account Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedBank,
                items: bankCodes.keys.map((bankName) {
                  return DropdownMenuItem<String>(
                    value: bankName,
                    child: Text(
                      bankName,
                      style: GoogleFonts.poppins(),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBank = value;
                    _selectedBankCode = bankCodes[value!];
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Select Bank',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _stateController,
                decoration: InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _streetController,
                decoration: InputDecoration(
                  labelText: 'Street Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      )
                    : Text('Connect'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// WebView Page to open the redirect URL
class WebViewPage extends StatefulWidget {
  final String url;

  WebViewPage({required this.url});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bank Authorization')),
      body: WebViewWidget(controller: _controller),
    );
  }
}


