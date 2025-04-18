
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

class _SigninState extends State<Signin> {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isObscured = true;



  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, String> payload = {
        'email': _emailController.text,
        "password": _passwordController.text
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
    return Scaffold(
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                CustomText(
                  'Retilda',
                  fontSize: 25.sp,
                  fontWeight: FontWeight.bold,
                  color: ROrange,
                ),
                SizedBox(height: 4.h),
                CustomText(
                  'Sign in',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                SizedBox(height: 4.h),
                CustomTextFormField(
                  controller: _emailController,
                  hintText: 'Email',
                  isPasswordField: false,
                  suffixIcon: Icons.email,
                  onChanged: (value) {},
                ),

                SizedBox(height: 4.h),

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

                
                SizedBox(height: 2.h),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ResetPassword()));
                  },
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: CustomText(
                      'Forgot password',
                      color: ROrange,
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                _isLoading
                    ? CircleAvatar(
                        radius: 25, 
                        backgroundColor:
                            Colors.grey.shade200, 
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue), 
                          strokeWidth: 3.0,
                        ),
                      )
                    : CustomBtn(
                        text: 'Sign in',
                        onPressed: _login,
                        backgroundColor: RButtoncolor,
                        borderRadius: 20.0,
                      ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CustomText(
                        'New user? ',
                        color: Colors.black,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Signup()));
                        },
                        child: CustomText(
                          'Sign up',
                          color: ROrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
