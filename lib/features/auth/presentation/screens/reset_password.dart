import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:retilda/Views/Auth/Signin.dart';
import 'package:retilda/Views/Widgets/dialogs.dart';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/features/auth/presentation/widgets/auth_ui.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  late final ApiClient _apiClient = ApiClient(session: AppSession());

  bool _isRequesting = false;
  bool _isUpdating = false;
  bool _isResetRequested = false; // To track if the reset was requested
  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideIn;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
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
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
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

  String _messageFrom(
    httpResponseBody,
    String fallback,
  ) {
    if (httpResponseBody is! String) {
      return fallback;
    }
    final decoded = _safeJson(httpResponseBody);
    final message = decoded['message'] as String?;
    if (message != null && message.trim().isNotEmpty) {
      return message;
    }
    final error = decoded['error'] as String?;
    if (error != null && error.trim().isNotEmpty) {
      return error;
    }
    return fallback;
  }

  String _resetFailureMessage(int statusCode, String body) {
    final backendMessage = _messageFrom(body, '');
    if (statusCode == 429) {
      return backendMessage.isNotEmpty
          ? backendMessage
          : 'Too many attempts were made. Please wait a bit before trying again.';
    }
    if (backendMessage.isNotEmpty) {
      return backendMessage;
    }
    return 'Unable to update password right now. Please try again.';
  }

  Future<void> requestPasswordReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isRequesting = true);

    try {
      final response = await _apiClient.post(
        'forgotPassword',
        auth: AuthScope.none,
        body: {"email": _emailController.text.trim()},
      );

      if (!mounted) {
        return;
      }

      setState(() => _isRequesting = false);

      if (response.statusCode == 200) {
        setState(() {
          _isResetRequested = true;
        });

        showAppNoticeSheet(
          context: context,
          title: 'Code sent',
          message: _messageFrom(
            response.body,
            'OTP has been sent to your email. Use the latest code to update your password securely.',
          ),
          tone: AppFeedbackTone.success,
          primaryLabel: 'Continue',
          icon: Icons.mail_outline_rounded,
        );
      } else {
        showAppAlert(
          context: context,
          title: 'Unable to send code',
          message: _messageFrom(
            response.body,
            'Unable to send reset OTP. Please try again.',
          ),
          tone: AppFeedbackTone.error,
          buttonText: 'Close',
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isRequesting = false);
      showAppAlert(
        context: context,
        title: 'Request failed',
        message: 'Unable to send reset OTP right now. Please try again.',
        tone: AppFeedbackTone.error,
        buttonText: 'Close',
      );
    }
  }

  Future<void> resetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final response = await _apiClient.post(
        'resetPassword',
        auth: AuthScope.none,
        body: {
          "email": _emailController.text.trim(),
          "password": _passwordController.text,
          "otp": _otpController.text,
        },
      );

      if (!mounted) {
        return;
      }

      setState(() => _isUpdating = false);

      if (response.statusCode == 200) {
        showAppNoticeSheet(
          context: context,
          title: 'Password updated',
          message: _messageFrom(
            response.body,
            'Your password has been updated successfully. Sign in again to continue.',
          ),
          tone: AppFeedbackTone.success,
          primaryLabel: 'Sign in',
          onPrimaryPressed: () {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const Signin()),
            );
          },
          icon: Icons.verified_user_rounded,
        );
      } else {
        final failureMessage =
            _resetFailureMessage(response.statusCode, response.body);
        showAppAlert(
          context: context,
          title: response.statusCode == 429
              ? 'Too many requests'
              : 'Update failed',
          message: failureMessage,
          tone: AppFeedbackTone.error,
          buttonText: response.statusCode == 429 ? 'Understood' : 'Try again',
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isUpdating = false);
      showAppAlert(
        context: context,
        title: 'Update failed',
        message: 'Unable to update password right now. Please try again.',
        tone: AppFeedbackTone.error,
        buttonText: 'Close',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      badge: !_isResetRequested ? 'Password Reset' : 'Update Password',
      title: !_isResetRequested
          ? 'Recover access without friction.'
          : 'Set a new password securely.',
      subtitle: !_isResetRequested
          ? 'Enter your account email and we will send a one-time code to continue.'
          : 'Use the latest code from your email and choose a fresh password.',
      icon: !_isResetRequested
          ? Icons.lock_reset_rounded
          : Icons.password_rounded,
      showBack: true,
      showHeroStats: false,
      child: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideIn,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isResetRequested) ...[
                  const AuthStatusMessage(
                    message:
                        'We will send a one-time code to your registered email address.',
                    isError: false,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'Email address',
                    hint: 'you@example.com',
                    controller: _emailController,
                    icon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter your email address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AuthPrimaryButton(
                    label: 'Request password reset',
                    onPressed: requestPasswordReset,
                    loading: _isRequesting,
                  ),
                ] else ...[
                  AuthTextField(
                    label: '6-digit OTP',
                    hint: 'Enter the code from email',
                    controller: _otpController,
                    icon: Icons.pin_outlined,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: (value) {
                      if (value == null || value.trim().length != 6) {
                        return 'Enter the 6-digit OTP.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'New password',
                    hint: 'Create a new password',
                    controller: _passwordController,
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter a new password.';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AuthPrimaryButton(
                    label: 'Update password',
                    onPressed: resetPassword,
                    loading: _isUpdating,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
