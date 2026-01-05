
import 'package:flutter/material.dart';
import 'package:retilda/Views/Auth/Signup.dart';
import 'package:retilda/Views/Auth/resetpass.dart';
import 'package:retilda/Views/Home/dashboard.dart';
import 'package:retilda/Views/Home/home.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/dialogs.dart';
import 'package:retilda/Views/Widgets/loader.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';





class Signin extends StatefulWidget {
  const Signin({Key? key}) : super(key: key);

  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> with SingleTickerProviderStateMixin {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isObscured = true;

  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideIn;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, String> payload = {
        'email': _emailController.text.trim(),
        "password": _passwordController.text.trim()
      };

      final String payloadJson = jsonEncode(payload);

      print('Request Payload: $payloadJson');

      final url = Uri.parse('https://retilda-fintech-3jy7.onrender.com/Api/login');
      final response = await http.post(
        url,
        body: payloadJson,
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print(response.body);
        final responseData = jsonDecode(response.body);
        final sharedPreferences = await SharedPreferences.getInstance();
        await sharedPreferences.setString('userData', jsonEncode(responseData));
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => HomePage()));
      } else {
        print(response.body);
        final responseData = jsonDecode(response.body);

        showDialog(
          context: context,
          builder: (context) {
            return CustomAlertDialog(
              title: 'Error',
              titleColor: Colors.red,
              message: responseData['message'],
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
    } catch (e) {
      print('Error: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFF6F7FB);
    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideIn,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: ROrange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.lock_open_rounded,
                              color: Colors.black87),
                        ),
                        const SizedBox(width: 10),
                        CustomText(
                          'Retilda',
                          fontSize: 23.sp,
                          fontWeight: FontWeight.w800,
                          color: ROrange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    CustomText(
                      'Welcome back',
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                    const SizedBox(height: 6),
                    CustomText(
                      'Access your marketplace and wallet.',
                      fontSize: 12.sp,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 22),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CustomTextFormField(
                            controller: _emailController,
                            hintText: 'Email',
                            isPasswordField: false,
                            suffixIcon: Icons.email,
                            onChanged: (value) {},
                          ),
                          SizedBox(height: 2.5.h),
                          CustomTextFormField(
                            controller: _passwordController,
                            hintText: 'Password',
                            isPasswordField: true,
                            onChanged: (value) {},
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ResetPassword()));
                              },
                              child: CustomText(
                                'Forgot password?',
                                color: ROrange,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(height: 3.h),
                          _isLoading
                              ? CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Colors.grey.shade200,
                                  child: const CircularProgressIndicator(
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.blue),
                                    strokeWidth: 3.0,
                                  ),
                                )
                              : CustomBtn(
                                  text: 'Sign in',
                                  onPressed: _login,
                                  backgroundColor: RButtoncolor,
                                  borderRadius: 20.0,
                                ),
                        ],
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomText(
                          'New user? ',
                          color: Colors.black87,
                          fontSize: 15.sp,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Signup()));
                          },
                          child: CustomText(
                            'Create account',
                            color: ROrange,
                            fontWeight: FontWeight.w800,
                            fontSize: 15.sp,
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
      ),
    );
  }
}
