import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:retilda/Views/Widgets/components.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRequesting = false;
  bool _isUpdating = false;
  bool _isResetRequested = false; // To track if the reset was requested

  Future<void> requestPasswordReset() async {
    setState(() => _isRequesting = true);

    final url =
        Uri.parse("https://retilda-fintech.onrender.com/Api/forgotPassword");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"email": _emailController.text}),
    );

    setState(() => _isRequesting = false);

    if (response.statusCode == 200) {
      setState(() {
        _isResetRequested = true; // Show the update password section
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Success"),
          content: const Text("OTP has been sent to your email."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error"),
          content: Text("Failed to send OTP: ${response.body}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> resetPassword() async {
    setState(() => _isUpdating = true);

    final url =
        Uri.parse("https://retilda-fintech.onrender.com/Api/resetPassword");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "password": _passwordController.text,
        "otp": _otpController.text,
      }),
    );

    setState(() => _isUpdating = false);

    if (response.statusCode == 200) {
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Success"),
          content: const Text("Password has been updated."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error"),
          content: Text("Failed to update password: ${response.body}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isResetRequested) ...[
              // Email Section
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _isRequesting ? null : requestPasswordReset,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _isRequesting ? Colors.grey : RButtoncolor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isRequesting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text("Request Password Reset",
                          style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ),
            ] else ...[
              // Update Password Section
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(labelText: "OTP"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "New Password"),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _isUpdating ? null : resetPassword,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _isUpdating ? Colors.grey : Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isUpdating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Update Password",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
