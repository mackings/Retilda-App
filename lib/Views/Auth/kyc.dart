import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Auth/Signin.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/dialogs.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;

class KYC extends ConsumerStatefulWidget {
  const KYC({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _KYCState();
}

class _KYCState extends ConsumerState<KYC> {
  TextEditingController _bvnController = TextEditingController();
  TextEditingController _dobController = TextEditingController();
  String? _token;
  String? _fullname;
  String? _email;
  bool loading = false;

  Future<void> _loadUserData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userDataString = sharedPreferences.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      String token = userData['data']['token'];
      String fullname = userData['data']['user']['fullname'];
      String email = userData['data']['user']['email'];

      setState(() {
        _token = token;
        _fullname = fullname;
        _email = email;
      });
      print("User Data >>> $userData");
    }
  }

  final String apiUrl = 'https://retilda.onrender.com/Api/createwallet';

  Future<void> createWallet() async {
    final url = Uri.parse(apiUrl);

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };

    final Map<String, dynamic> payload = {
      "walletName": _fullname,
      "customerName": _fullname,
      "bvn": _bvnController.text,
      "bvnDateOfBirth": _dobController.text,
      "customerEmail": _email
    };

    try {
      setState(() {
        loading = true;
      });
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );

      setState(() {
        loading = false;
      });

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        print('Wallet created successfully: $responseBody');

        showDialog(
          context: context,
          builder: (context) {
            return CustomAlertDialog(
              title: 'Success',
              titleColor: Colors.blue,
              message: "You are now a Premium user.",
              onClosePressed: () {
                Navigator.pop(context);
              },
              onButtonPressed: () {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => Signin()));
              },
            );
          },
        );
      } else {
        final responseBody = jsonDecode(response.body);

        if (responseBody['message'] ==
            "bvnDetails.bvn could not be validated") {
          showDialog(
            context: context,
            builder: (context) {
              return CustomAlertDialog(
                title: 'Error',
                titleColor: Colors.red,
                message: "BVN is Invalid",
                onClosePressed: () {
                  Navigator.of(context).pop();
                },
                onButtonPressed: () {},
              );
            },
          );
        }

        print('Failed to create wallet: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (error) {
      setState(() {
        loading = false;
      });
      print('Error creating wallet: $error');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
        print(_dobController.text);
      });
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
        title: CustomText(
          'Kyc',
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            SizedBox(height: 5.h),
            CustomTextFormField(
              controller: _bvnController,
              hintText: 'BVN',
              suffixIcon: Icons.manage_accounts_sharp,
              onSuffixIconTap: () {},
            ),
            SizedBox(height: 2.h),
            MyTextFormField(
              controller: _dobController,
              hintText: 'Date of Birth',
              suffixIcon: Icons.date_range,
              onSuffixIconTap: () {
                _selectDate(context);
              },
            ),
            SizedBox(height: 5.h),
            CustomBtn(
              backgroundColor: RButtoncolor,
              text: loading ? "Validating BVN..." : "Validate BVN",
              onPressed: loading
                  ? null
                  : createWallet, // Disable the button if loading
            ),
          ],
        ),
      ),
    );
  }
}

class MyTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final IconData suffixIcon;
  final VoidCallback onSuffixIconTap;

  const MyTextFormField({
    this.controller,
    required this.hintText,
    required this.suffixIcon,
    required this.onSuffixIconTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      decoration: BoxDecoration(
          border: Border.all(width: 0.5, color: Colors.grey),
          borderRadius: BorderRadius.circular(10)),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(),
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(vertical: 13.0, horizontal: 20.0),
          suffixIcon: GestureDetector(
            onTap: onSuffixIconTap,
            child: Icon(suffixIcon),
          ),
        ),
      ),
    );
  }
}
