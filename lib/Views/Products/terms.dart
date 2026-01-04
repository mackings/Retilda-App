import 'package:flutter/material.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:sizer/sizer.dart';

class TermsAndPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFF6F7FB);
    const Color deepBlue = Color(0xFF103C57);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        title: CustomText(
          'Terms & Policy',
          fontSize: 17.sp,
          fontWeight: FontWeight.w800,
          color: deepBlue,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0C3554), Color(0xFF145E8D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 12),
                  )
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    'Please read carefully',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 6),
                  CustomText(
                    'These terms outline how Retilda protects your data, payments, and purchases.',
                    fontSize: 13.sp,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Introduction',
              body:
                  'Welcome to the Retilda Property Enterprise app. By using our services, you agree to these terms. Please review them before continuing.',
            ),
            _SectionCard(
              title: 'Acceptance of Terms',
              body:
                  'These terms govern your access to the platform. If you do not agree, please refrain from using the app or site.',
            ),
            _SectionCard(
              title: 'Services Offered',
              body:
                  'We provide access to electronic and household equipment with options to buy outright or via Buy Now, Pay Later (BNPL). You can browse, purchase, manage orders, and track deliveries.',
            ),
            _SectionCard(
              title: 'User Accounts',
              bulletPoints: [
                'Provide accurate and current information during registration.',
                'Keep your credentials secure; you are responsible for activity on your account.',
                'We may suspend or terminate accounts for violations.',
              ],
            ),
            _SectionCard(
              title: 'Eligibility',
              bulletPoints: [
                '18+ years old and able to enter a binding contract.',
                'Nigerian citizen residing in Nigeria with a verifiable address.',
                'Valid delivery address, phone number, and email.',
                'Provide NIN or BVN for verification.',
                'Hold a valid Naira payment card and permit automated payments.',
              ],
            ),
            _SectionCard(
              title: 'Payment Terms',
              bulletPoints: [
                'Payments are subject to verification.',
                'BNPL users must follow the agreed schedule; late or missed payments may incur penalties.',
                'Prices may change without prior notice.',
              ],
            ),
            _SectionCard(
              title: 'Disclaimer',
              body:
                  'Retilda does not manufacture listed products. Manufacturers provide descriptions and are responsible for defects or damages per their terms. Retilda is not liable for manufacturing issues.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? body;
  final List<String>? bulletPoints;

  const _SectionCard({
    required this.title,
    this.body,
    this.bulletPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            title,
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF103C57),
          ),
          const SizedBox(height: 8),
          if (body != null)
            CustomText(
              body!,
              fontSize: 12.sp,
              color: Colors.grey[800],
              //textAlign: TextAlign.start,
            ),
          if (bulletPoints != null) ...[
            const SizedBox(height: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: bulletPoints!
                  .map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("• ",
                              style: TextStyle(color: Colors.black87)),
                          Expanded(
                            child: CustomText(
                              point,
                              fontSize: 12.sp,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
