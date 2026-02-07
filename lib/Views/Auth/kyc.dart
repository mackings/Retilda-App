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
  String? token;
  String? _fullname;
  String? _email;
  bool loading = false;

  Future<void> _loadUserData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userDataString = sharedPreferences.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      String Token = userData['data']['token'];
      String UserId = userData['data']['user']['_id'];
      String Wallet = userData['data']['user']['wallet']['accountNumber'];
      bool userDirectdebit = userData['data']['user']['isDirectDebit'];

      setState(() {
        token = Token;
      });
      print(token);
    }
  }

  final String kycApiUrl = 'https://retildaserver.vercel.app/Api/kyc';

  Future<void> updateKyc() async {
    final url = Uri.parse(kycApiUrl);

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final Map<String, dynamic> payload = {
      "bvnDateOfBirth": _dobController.text,
      "bvn": _bvnController.text,
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
        print('KYC updated successfully: $responseBody');

        showDialog(
          context: context,
          builder: (context) {
            return CustomAlertDialog(
              title: 'Success',
              titleColor: Colors.blue,
              message: responseBody['message'] ?? "KYC updated successfully.",
              onClosePressed: () {
                Navigator.pop(context);
              },
              onButtonPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Signin()),
                );
              },
            );
          },
        );
      } else {
        final responseBody = jsonDecode(response.body);
        print('Failed to update KYC: ${response.statusCode}');
        print('Response body: ${response.body}');
        print(token);

        showDialog(
          context: context,
          builder: (context) {
            return CustomAlertDialog(
              title: 'Error',
              titleColor: Colors.red,
              message: responseBody['message'] ?? "Failed to update KYC.",
              onClosePressed: () {
                Navigator.of(context).pop();
              },
              onButtonPressed: () {},
            );
          },
        );
      }
    } catch (error) {
      setState(() {
        loading = false;
      });
      print('Error updating KYC: $error');
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
    const Color pageBg = Color(0xFFF6F7FB);
    const Color deepBlue = Color(0xFF103C57);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        title: CustomText(
          'KYC Verification',
          fontSize: 17.sp,
          fontWeight: FontWeight.w800,
          color: deepBlue,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0C3554), Color(0xFF145E8D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 12),
                  )
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              "Secure your account",
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 4),
                            CustomText(
                              "Provide BVN and date of birth to verify your identity.",
                              fontSize: 13.sp,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.lock_clock, color: Colors.white70, size: 18),
                      const SizedBox(width: 6),
                      CustomText(
                        "Takes less than a minute",
                        color: Colors.white,
                        fontSize: 12.sp,
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    "Verification details",
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: deepBlue,
                  ),
                  const SizedBox(height: 12),
                  CustomText(
                    "Your BVN is used only for identity verification and is never stored.",
                    fontSize: 12.sp,
                    color: Colors.grey[700],
                  ),
                  SizedBox(height: 2.h),
                  CustomTextFormField(
                    controller: _bvnController,
                    hintText: 'Enter BVN',
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
                  SizedBox(height: 3.h),
                  CustomBtn(
                    backgroundColor: RButtoncolor,
                    text: loading ? "Validating BVN..." : "Validate BVN",
                    onPressed: loading ? null : updateKyc,
                  ),
                  const SizedBox(height: 6),
                  CustomText(
                    "By continuing, you agree to our terms and data policy.",
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                ],
              ),
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
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(width: 0.5, color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
          suffixIcon: GestureDetector(
            onTap: onSuffixIconTap,
            child: Icon(suffixIcon, color: const Color(0xFF103C57)),
          ),
        ),
      ),
    );
  }
}
