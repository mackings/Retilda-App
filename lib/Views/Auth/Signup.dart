import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:retilda/Views/Auth/Signin.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/dialogs.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;

class Signup extends StatefulWidget {
  const Signup({Key? key}) : super(key: key);

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _fullname = TextEditingController();

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email cannot be empty';
    }
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number cannot be empty';
    }
    if (value.length != 11) {
      return 'Phone number must be 11 digits';
    }
    return null;
  }

  Future<void> _signup() async {
    setState(() {
      _isLoading = true;
    });

    final url = 'https://retilda.onrender.com/Api/register';

    final payload = {
      "fullname": _fullname.text.trim(),
      "email": _email.text.trim(),
      "phone": _phone.text.trim(),
      "password": _password.text.trim(),
      "isVerified": false,
      "accounttype": "user",
      "wallet": {"status": "Not available"}
    };

    try {
      print(payload);

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      setState(() {
        _isLoading = false;
      });

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print(response.body);
        _showAlert('Success', responseData['message'] ?? 'Signup successful');
           Navigator.push(
                context, MaterialPageRoute(builder: (context) => Signin()));
      } else {
        print(response.body);
        _showAlert('Error', responseData['message'] ?? 'Signup failed');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showAlert('Error', 'An error occurred. Please try again.');
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return CustomAlertDialog(
          title: title,
          titleColor: Colors.red,
          message: message,
          onClosePressed: () {
            Navigator.pop(context);
          },

          onButtonPressed: () {
             Navigator.pop(context);

          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          body: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.1),
                      CustomText(
                        'Retilda',
                        fontSize: 25.sp,
                        fontWeight: FontWeight.bold,
                        color: ROrange,
                      ),
                      SizedBox(height: 4.h),
                      CustomText(
                        'Sign up',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      SizedBox(height: 4.h),
                      CustomTextFormField(
                        controller: _fullname,
                        onSuffixIconTap: () {},
                        hintText: 'Full Name',
                        onChanged: (value) {},
                      ),
                      SizedBox(height: 4.h),
                      CustomTextFormField(
                        controller: _email,
                        hintText: 'Email',
                        suffixIcon: Icons.email,
                        validator: _validateEmail,
                        onChanged: (value) {},
                        onSuffixIconTap: () {},
                      ),
                      SizedBox(height: 4.h),
                      CustomTextFormField(
                        controller: _phone,
                        hintText: 'Phone Number',
                        suffixIcon: Icons.phone,
                        validator: _validatePhoneNumber,
                        onChanged: (value) {},
                        onSuffixIconTap: () {},
                      ),
                      SizedBox(height: 4.h),
                      CustomTextFormField(
                        controller: _password,
                        hintText: 'Password',
                        suffixIcon: _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        obscureText: !_isPasswordVisible,
                        onSuffixIconTap: _togglePasswordVisibility,
                        onChanged: (value) {},
                      ),
                      SizedBox(height: 4.h),
                      CustomBtn(
                        text: _isLoading ? "Signing you up.." : "Sign up",
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            _signup();
                          }
                        },
                        backgroundColor: RButtoncolor,
                        borderRadius: 20.0,
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.03),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            'Already have an account? ',
                            color: Colors.black,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Signin()),
                              );
                            },
                            child: CustomText(
                              'Sign in',
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
