import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:retilda/Views/Widgets/dialogs.dart';
import 'package:retilda/Views/Auth/Signin.dart';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/features/auth/presentation/widgets/auth_ui.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.lockEmail = true,
  });

  final String email;
  final bool lockEmail;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  late final ApiClient _apiClient = ApiClient(session: AppSession());

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;
  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideIn;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _safeJson(String body) {
    try {
      final decoded = body.isEmpty ? null : jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  String _messageFrom(Map<String, dynamic> body, String fallback) {
    final message = body['message'] as String?;
    if (message != null && message.trim().isNotEmpty) {
      return message;
    }
    return fallback;
  }

  Future<void> _verifyEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.post(
        'email-verification/verify',
        auth: AuthScope.none,
        body: {
          'email': email,
          'otp': otp,
        },
      );
      final responseData = _safeJson(response.body);

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => Signin(initialEmail: email),
          ),
        );
        return;
      }

      setState(() {
        _errorMessage = _messageFrom(
          responseData,
          'Unable to verify email. Please check the code and try again.',
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage =
            'Unable to verify email right now. Please try again shortly.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Email is required to resend the code.');
      return;
    }

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.post(
        'email-verification/send',
        auth: AuthScope.none,
        body: {
          'email': email,
        },
      );
      final responseData = _safeJson(response.body);

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        showAppSnackBar(
          context,
          message: _messageFrom(
            responseData,
            'A fresh verification code has been sent to your email.',
          ),
          tone: AppFeedbackTone.success,
        );
        return;
      }

      setState(() {
        _errorMessage = _messageFrom(
          responseData,
          'Unable to resend the verification code right now.',
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Unable to resend the code. Please try again shortly.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      badge: 'Email Verification',
      title: 'Confirm your email to continue.',
      subtitle:
          'Enter the 6-digit code sent to your inbox to activate your account before sign-in.',
      icon: Icons.mark_email_read_rounded,
      showBack: true,
      child: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideIn,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AuthStatusMessage(
                  message:
                      'Verification codes expire quickly. If the code fails, request a new one and use the latest email.',
                  isError: false,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label: 'Email address',
                  hint: 'you@example.com',
                  controller: _emailController,
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  readOnly: widget.lockEmail,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().length != 6) {
                      return 'Enter the 6-digit code from your email.';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: '6-digit code',
                    prefixIcon: const Icon(Icons.verified_user_outlined),
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFFF7F9FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  AuthStatusMessage(message: _errorMessage!),
                ],
                const SizedBox(height: 20),
                AuthPrimaryButton(
                  label: 'Verify email',
                  onPressed: _verifyEmail,
                  loading: _isVerifying,
                ),
                const SizedBox(height: 12),
                AuthSecondaryButton(
                  label: _isResending ? 'Sending code...' : 'Resend code',
                  icon: Icons.refresh_rounded,
                  onPressed: _resendCode,
                  loading: _isResending,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
