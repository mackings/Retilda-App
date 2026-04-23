import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Auth/Signin.dart';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/presentation/widgets/dialogs.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/features/auth/presentation/widgets/auth_ui.dart';

class KYC extends ConsumerStatefulWidget {
  const KYC({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _KYCState();
}

class _KYCState extends ConsumerState<KYC> {
  final TextEditingController _bvnController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  bool loading = false;
  late final AppSession _session = AppSession();
  late final ApiClient _apiClient = ApiClient(session: _session);

  Future<void> updateKyc() async {
    final bvn = _bvnController.text.trim();
    final dob = _dobController.text.trim();

    if (bvn.isEmpty || dob.isEmpty) {
      showAppSnackBar(
        context,
        message: 'Enter your BVN and date of birth to continue.',
        tone: AppFeedbackTone.warning,
      );
      return;
    }

    if (bvn.length != 11 || int.tryParse(bvn) == null) {
      showAppSnackBar(
        context,
        message: 'BVN must be an 11-digit number.',
        tone: AppFeedbackTone.warning,
      );
      return;
    }

    final Map<String, dynamic> payload = {
      "bvnDateOfBirth": dob,
      "bvn": bvn,
    };

    try {
      setState(() {
        loading = true;
      });

      final response = await _apiClient.post(
        'kyc',
        body: payload,
      );

      if (!mounted) return;
      setState(() {
        loading = false;
      });

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        await showAppAlert(
          context: context,
          title: 'Verification complete',
          message: responseBody['message'] ?? 'KYC updated successfully.',
          tone: AppFeedbackTone.success,
          buttonText: 'Sign in',
          icon: Icons.verified_user_outlined,
          onButtonPressed: () {
            Navigator.of(context).pop();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Signin()),
            );
          },
        );
      } else {
        final responseBody = jsonDecode(response.body);
        await showAppAlert(
          context: context,
          title: 'Verification failed',
          message: responseBody['message'] ?? 'Failed to update KYC.',
          tone: AppFeedbackTone.error,
          buttonText: 'Okay',
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
      await showAppAlert(
        context: context,
        title: 'Verification failed',
        message: 'Unable to complete KYC right now. Please try again.',
        tone: AppFeedbackTone.error,
        buttonText: 'Okay',
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _bvnController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      badge: 'Identity check',
      title: 'KYC Verification',
      subtitle:
          'Confirm your BVN and date of birth to keep your Retilda account secure.',
      icon: Icons.verified_user_outlined,
      showBack: true,
      showHeroStats: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthStatusMessage(
            message:
                'Your BVN is used only for identity verification and is never stored.',
            isError: false,
          ),
          const SizedBox(height: 18),
          AuthTextField(
            label: 'BVN',
            hint: 'Enter 11-digit BVN',
            controller: _bvnController,
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            maxLength: 11,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: 'Date of birth',
            hint: 'YYYY-MM-DD',
            controller: _dobController,
            icon: Icons.calendar_month_rounded,
            readOnly: true,
            suffixIcon: Icons.date_range_rounded,
            onSuffixTap: () => _selectDate(context),
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: 22),
          AuthPrimaryButton(
            label: loading ? 'Validating BVN...' : 'Validate BVN',
            loading: loading,
            onPressed: updateKyc,
          ),
          const SizedBox(height: 12),
          const AuthStatusMessage(
            message: 'Takes less than a minute. Make sure your details match.',
            isError: false,
          ),
        ],
      ),
    );
  }
}
