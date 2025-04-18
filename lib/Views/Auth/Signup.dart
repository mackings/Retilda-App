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

// late FirebaseMessaging _messaging;
// String _notificationText = "No new notifications";


//   void _initializeFirebaseMessaging() async {
//     _messaging = FirebaseMessaging.instance;

//     // Request permission for iOS
//     NotificationSettings settings = await _messaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );

//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       print('User granted permission');
//     } else {
//       print('User declined or has not granted permission');
//     }

//     // Get the FCM token
//     String? token = await _messaging.getToken();
//     print("FCM Token: $token");

//     // Listen for foreground messages
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       print("Received a foreground message: ${message.notification?.title}");
//       setState(() {
//         _notificationText = message.notification?.body ?? "No notification body";
//       });
//     });

//     // Handle when the app is opened from a notification
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       print("Notification clicked: ${message.notification?.title}");
//     });
//   }



  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _fullname = TextEditingController();
  final TextEditingController _referralcode = TextEditingController();

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

    final url = 'https://retilda-fintech-3jy7.onrender.com/Api/signUp';

    final payload = {
      "fullName": _fullname.text.trim(),
      "email": _email.text.trim(),
      "phone": _phone.text.trim(),
      "password": _password.text.trim(),
      "isVerified": false,
      "accounttype": "user",
      "wallet": {"status": "Not available"},
      "referralCode": _referralcode.text.trim()
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

      if (response.statusCode == 201) {
        print(response.body);
        _showAlert2('Success', responseData['message'] ?? 'Signup successful');

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
      barrierDismissible: false,
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


    void _showAlert2(String title, String message) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return CustomAlertDialog(
          title: title,
          titleColor: Colors.blue,
          message: message,
          onClosePressed: () {
            Navigator.pop(context);
          },

          onButtonPressed: () {
        Navigator.push(
              context, MaterialPageRoute(builder: (context) => Signin()));

          },
        );
      },
    );
  }

  @override
  void initState() {
   // _initializeFirebaseMessaging();
    super.initState();
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
                        isPasswordField: false,
                        suffixIcon: Icons.person_2,
                        hintText: 'Full Name',
                        onChanged: (value) {},
                      ),

                      SizedBox(height: 4.h),

                      CustomTextFormField(
                        controller: _email,
                        hintText: 'Email',
                        isPasswordField: false,
                        suffixIcon: Icons.email,
                        validator: _validateEmail,
                        onChanged: (value) {},
                      ),

                      SizedBox(height: 4.h),

                      CustomTextFormField(
                        controller: _phone,
                        hintText: 'Phone Number',
                        isPasswordField: false,
                        suffixIcon: Icons.phone,
                        validator: _validatePhoneNumber,
                        onChanged: (value) {},
                      ),

                      SizedBox(height: 4.h),

                      CustomTextFormField(
                        controller: _password,
                        hintText: 'Password',
                        isPasswordField: true,
                        onChanged: (value) {},
                      ),

                      SizedBox(height: 4.h),
                      
                        CustomTextFormField(
                        controller: _referralcode,
                        hintText: 'Refferal Code (Optional)',
                        isPasswordField: false,
                        suffixIcon: Icons.accessibility,
                       // validator: _validatePhoneNumber,
                        onChanged: (value) {},
                      ),

                      SizedBox(height: 4.h),
                      CustomBtn(
                        text: _isLoading ? "Creating your account.." : "Sign up",
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
