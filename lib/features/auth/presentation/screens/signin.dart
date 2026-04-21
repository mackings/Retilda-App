import 'package:flutter/material.dart';
import 'package:retilda/Views/Auth/Signup.dart';
import 'package:retilda/Views/Auth/resetpass.dart';
import 'package:retilda/Views/Home/home.dart';
import 'package:retilda/Views/Widgets/dialogs.dart';
import 'dart:convert';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/security/biometric_auth_service.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/features/auth/presentation/screens/email_verification.dart';
import 'package:retilda/features/auth/presentation/widgets/auth_ui.dart';

class Signin extends StatefulWidget {
  const Signin({
    super.key,
    this.initialEmail,
  });

  final String? initialEmail;

  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isBiometricLoading = false;
  bool _biometricReady = false;
  final AppSession _session = AppSession();
  late final ApiClient _apiClient = ApiClient(session: _session);
  late final BiometricAuthService _biometricAuth = BiometricAuthService();

  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideIn;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail ?? '';
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _loadBiometricState();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your email address.';
    }
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter your password.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailController.dispose();
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

  String _messageFrom(Map<String, dynamic> body, String fallback) {
    final message = body['message'] as String?;
    if (message != null && message.trim().isNotEmpty) {
      return message;
    }
    return fallback;
  }

  Future<void> _loadBiometricState() async {
    final enabled = await _session.isBiometricLoginEnabled();
    final hasCredentials = await _session.biometricCredentials();
    final canAuthenticate = await _biometricAuth.canAuthenticate();

    if (!mounted) {
      return;
    }

    setState(() {
      _biometricReady = enabled && hasCredentials != null && canAuthenticate;
    });
  }

  Future<void> _offerBiometricOptIn({
    required String email,
    required String password,
    required bool isEmailVerified,
  }) async {
    if (!isEmailVerified) {
      return;
    }

    final alreadyEnabled = await _session.isBiometricLoginEnabled();
    if (alreadyEnabled) {
      await _session.saveBiometricCredentials(
        email: email,
        password: password,
      );
      return;
    }

    final canAuthenticate = await _biometricAuth.canAuthenticate();
    if (!canAuthenticate || !mounted) {
      return;
    }

    final shouldEnable = await showAppNoticeSheet<bool>(
          context: context,
          title: 'Enable biometric login?',
          message:
              'Use fingerprint or Face ID for faster sign-in on this device after verified access.',
          tone: AppFeedbackTone.info,
          primaryLabel: 'Enable now',
          secondaryLabel: 'Not now',
          onPrimaryPressed: () => Navigator.pop(context, true),
          onSecondaryPressed: () => Navigator.pop(context, false),
          icon: Icons.fingerprint_rounded,
        ) ??
        false;

    if (!shouldEnable) {
      return;
    }

    await _session.saveBiometricCredentials(
      email: email,
      password: password,
    );
    await _session.setBiometricLoginEnabled(true);

    if (!mounted) {
      return;
    }

    setState(() {
      _biometricReady = true;
    });

    showAppSnackBar(
      context,
      message: 'Biometric login enabled for this device.',
      tone: AppFeedbackTone.success,
    );
  }

  Future<void> _handleSuccessfulLogin(
    Map<String, dynamic> responseData, {
    required String email,
    required String password,
    required bool fromBiometric,
  }) async {
    await _session.saveUserSession(responseData);
    final user = responseData['data']?['user'] as Map<String, dynamic>?;
    final isEmailVerified = user?['isEmailVerified'] == true;

    if (!fromBiometric) {
      await _offerBiometricOptIn(
        email: email,
        password: password,
        isEmailVerified: isEmailVerified,
      );
    }

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  void _routeToVerification(String email) {
    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EmailVerificationScreen(email: email),
      ),
    );
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, String> payload = {
        'email': _emailController.text.trim(),
        "password": _passwordController.text.trim()
      };

      final response = await _apiClient.post(
        'login',
        auth: AuthScope.none,
        body: payload,
      );
      final responseData = _safeJson(response.body);

      if (response.statusCode == 200) {
        await _handleSuccessfulLogin(
          responseData,
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fromBiometric: false,
        );
      } else if (response.statusCode == 403 &&
          ((responseData['code'] as String?) == 'EMAIL_VERIFICATION_REQUIRED' ||
              responseData['emailVerificationRequired'] == true)) {
        _routeToVerification(
          (responseData['email'] as String?) ?? _emailController.text.trim(),
        );
      } else {
        if (!mounted) {
          return;
        }
        showAppAlert(
          context: context,
          title: 'Sign-in failed',
          message: _messageFrom(
            responseData,
            'Unable to sign in. Please try again.',
          ),
          tone: AppFeedbackTone.error,
          buttonText: 'Try again',
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      showAppAlert(
        context: context,
        title: 'Something went wrong',
        message: e.toString(),
        tone: AppFeedbackTone.error,
        buttonText: 'Close',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loginWithBiometrics() async {
    final credentials = await _session.biometricCredentials();
    if (credentials == null) {
      await _session.clearBiometricLogin();
      if (!mounted) {
        return;
      }
      setState(() {
        _biometricReady = false;
      });
      showAppSnackBar(
        context,
        message: 'Biometric login is not set up on this device.',
        tone: AppFeedbackTone.warning,
      );
      return;
    }

    setState(() {
      _isBiometricLoading = true;
    });

    try {
      final authenticated = await _biometricAuth.authenticate();
      if (!authenticated) {
        return;
      }

      final response = await _apiClient.post(
        'login',
        auth: AuthScope.none,
        body: credentials,
      );
      final responseData = _safeJson(response.body);

      if (response.statusCode == 200) {
        await _handleSuccessfulLogin(
          responseData,
          email: credentials['email']!,
          password: credentials['password']!,
          fromBiometric: true,
        );
        return;
      }

      if (response.statusCode == 403 &&
          ((responseData['code'] as String?) == 'EMAIL_VERIFICATION_REQUIRED' ||
              responseData['emailVerificationRequired'] == true)) {
        await _session.clearBiometricLogin();
        if (mounted) {
          setState(() {
            _biometricReady = false;
          });
        }
        _routeToVerification(
          (responseData['email'] as String?) ?? credentials['email']!,
        );
        return;
      }

      await _session.clearBiometricLogin();
      if (!mounted) {
        return;
      }

      setState(() {
        _biometricReady = false;
      });

      showAppAlert(
        context: context,
        title: 'Biometric login unavailable',
        message:
            'Your saved biometric sign-in needs to be set up again. Please sign in with email and password.',
        tone: AppFeedbackTone.error,
        buttonText: 'Use password instead',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      showAppAlert(
        context: context,
        title: 'Authentication error',
        message: e.toString(),
        tone: AppFeedbackTone.error,
        buttonText: 'Close',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBiometricLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      badge: 'Sign In',
      title: 'Access your account with confidence.',
      subtitle:
          'Securely manage purchases, wallet activity, and delivery updates from one place.',
      icon: Icons.lock_open_rounded,
      showHeroStats: false,
      footer: AuthFooterPrompt(
        text: 'New to Retilda?',
        action: 'Create account',
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Signup()),
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
                  label: 'Email address',
                  hint: 'you@example.com',
                  controller: _emailController,
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passwordController,
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ResetPassword(),
                        ),
                      );
                    },
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 8),
                AuthPrimaryButton(
                  label: 'Sign in',
                  onPressed: _login,
                  loading: _isLoading,
                ),
                if (_biometricReady) ...[
                  const SizedBox(height: 12),
                  AuthSecondaryButton(
                    label: _isBiometricLoading
                        ? 'Authenticating...'
                        : 'Use fingerprint / Face ID',
                    icon: Icons.fingerprint_rounded,
                    onPressed: _loginWithBiometrics,
                    loading: _isBiometricLoading,
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
