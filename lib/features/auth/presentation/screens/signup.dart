import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:retilda/Views/Auth/Signin.dart';
import 'package:retilda/Views/Widgets/dialogs.dart';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/features/auth/presentation/screens/email_verification.dart';
import 'package:retilda/features/auth/presentation/widgets/auth_ui.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> with SingleTickerProviderStateMixin {
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
//     } else {
//     }

//     // Get the FCM token
//     String? token = await _messaging.getToken();

//     // Listen for foreground messages
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       setState(() {
//         _notificationText = message.notification?.body ?? "No notification body";
//       });
//     });

//     // Handle when the app is opened from a notification
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//     });
//   }

  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideIn;
  late final Animation<double> _fadeIn;

  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _fullname = TextEditingController();
  final TextEditingController _referralcode = TextEditingController();
  late final ApiClient _apiClient = ApiClient(session: AppSession());

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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password cannot be empty';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _signup() async {
    setState(() {
      _isLoading = true;
    });

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
      final response = await _apiClient.post(
        'signUp',
        auth: AuthScope.none,
        body: payload,
      );

      setState(() {
        _isLoading = false;
      });

      final responseData = _safeJson(response.body);

      if (response.statusCode == 201) {
        final user = responseData['user'] as Map<String, dynamic>?;
        final signupEmail = (user?['email'] as String?) ?? _email.text.trim();
        final requiresVerification =
            responseData['emailVerificationRequired'] == true;

        if (requiresVerification) {
          _showEmailVerificationPrompt(
            responseData['message'] as String? ??
                'Account created successfully. Verify your email to continue.',
            signupEmail,
          );
        } else {
          _showAlert2(
              'Success', responseData['message'] ?? 'Signup successful');
        }
      } else {
        _showAlert('Error', responseData['message'] ?? 'Signup failed');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showAlert('Error', 'An error occurred. Please try again.');
    }
  }

  Map<String, dynamic> _safeJson(String body) {
    try {
      final decoded = body.isEmpty ? null : jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  void _showAlert(String title, String message) {
    showAppAlert(
      context: context,
      title: title,
      message: message,
      tone: AppFeedbackTone.error,
      barrierDismissible: false,
      buttonText: 'Close',
    );
  }

  void _showAlert2(String title, String message) {
    showAppAlert(
      context: context,
      title: title,
      message: message,
      tone: AppFeedbackTone.success,
      barrierDismissible: false,
      buttonText: 'Sign in',
      onButtonPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Signin()),
        );
      },
    );
  }

  void _showEmailVerificationPrompt(String message, String email) {
    showAppNoticeSheet(
      context: context,
      title: 'Verify your email',
      message: message,
      tone: AppFeedbackTone.info,
      primaryLabel: 'Enter code',
      secondaryLabel: 'Later',
      onPrimaryPressed: () {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(email: email),
          ),
        );
      },
      onSecondaryPressed: () => Navigator.pop(context),
      icon: Icons.mark_email_read_rounded,
    );
  }

  @override
  void initState() {
    // _initializeFirebaseMessaging();
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 520));
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _fullname.dispose();
    _referralcode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      badge: 'Open Account',
      title: 'Create a secure account in minutes.',
      subtitle:
          'Set up your Retilda profile to shop, pay, and track orders with a cleaner workflow.',
      icon: Icons.person_add_alt_1_rounded,
      showHeroStats: false,
      footer: AuthFooterPrompt(
        text: 'Already have an account?',
        action: 'Sign in',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Signin()),
          );
        },
      ),
      child: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideIn,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthTextField(
                  label: 'Full name',
                  hint: 'Jane Doe',
                  controller: _fullname,
                  icon: Icons.badge_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required';
                    }

                    final words = value.trim().split(RegExp(r'\s+'));
                    if (words.length < 2) {
                      return 'Please enter your full name';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label: 'Email address',
                  hint: 'you@example.com',
                  controller: _email,
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label: 'Phone number',
                  hint: '08000000000',
                  controller: _phone,
                  icon: Icons.phone_iphone_rounded,
                  keyboardType: TextInputType.phone,
                  validator: _validatePhoneNumber,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label: 'Password',
                  hint: 'Create a strong password',
                  controller: _password,
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label: 'Referral code',
                  hint: 'Optional',
                  controller: _referralcode,
                  icon: Icons.card_giftcard_rounded,
                ),
                const SizedBox(height: 20),
                AuthPrimaryButton(
                  label: 'Create account',
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _signup();
                    }
                  },
                  loading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
