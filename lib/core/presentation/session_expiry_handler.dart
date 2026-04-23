import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:retilda/core/presentation/widgets/dialogs.dart';
import 'package:retilda/features/auth/presentation/screens/signin.dart';

class SessionExpiryHandler {
  SessionExpiryHandler._();

  static final navigatorKey = GlobalKey<NavigatorState>();
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static bool _dialogVisible = false;

  static bool isExpiredTokenResponse({
    required int statusCode,
    required String body,
  }) {
    if (statusCode != 401) return false;

    final message = _messageFromBody(body).toLowerCase();
    return message.contains('token has expired') ||
        message.contains('invalid token') ||
        message.contains('unauthorized');
  }

  static Future<void> handleExpiredSession({
    required Future<void> Function() clearSession,
  }) async {
    final shouldShowDialog = !_dialogVisible;
    if (shouldShowDialog) {
      _dialogVisible = true;
    }

    await clearSession();

    if (!shouldShowDialog) return;

    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      _dialogVisible = false;
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Your session has expired. Please sign in again.'),
        ),
      );
      return;
    }

    void routeToSignIn() {
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;

      _dialogVisible = false;
      if (navigator.canPop()) {
        navigator.pop();
      }
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Signin()),
        (_) => false,
      );
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CustomAlertDialog(
        title: 'Session expired',
        message:
            'Your login session has expired. Please sign in again to continue.',
        titleColor: Colors.orange,
        buttonText: 'Sign in again',
        icon: Icons.lock_clock_rounded,
        onClosePressed: routeToSignIn,
        onButtonPressed: routeToSignIn,
      ),
    );

    _dialogVisible = false;
  }

  static String _messageFromBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String) return message;
      }
    } catch (_) {
      return body;
    }
    return body;
  }
}
