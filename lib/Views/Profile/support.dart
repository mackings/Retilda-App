import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/widgets.dart';

class Support extends StatefulWidget {
  const Support({super.key});

  @override
  State<Support> createState() => _SupportState();
}

class _SupportState extends State<Support> {
  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: 'support@retildapropertyenterprise.com',
        query: Uri.encodeQueryComponent('Hello, I need help with...'));
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch email client')));
    }
  }

  Future<void> _launchWhatsApp() async {
    final Uri whatsappLaunchUri = Uri.parse("https://wa.me/2348061931283");
    if (await canLaunchUrl(whatsappLaunchUri)) {
      await launchUrl(whatsappLaunchUri);
    } else {
      final String whatsappScheme = "whatsapp://send?phone=2348061931283";
      final Uri whatsappUri = Uri.parse(whatsappScheme);
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch WhatsApp')));
      }
    }
  }

  Future<void> _launchCall() async {
    final Uri callLaunchUri = Uri.parse("tel:+2348061931283");
    if (await canLaunchUrl(callLaunchUri)) {
      await launchUrl(callLaunchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not make the call')));
    }
  }

  Future<void> _launchGuide(BuildContext context) async {
    final Uri youtubeUri =
        Uri.parse("https://youtu.be/DNpEHq_WKvQ?feature=shared");

    if (await canLaunchUrl(youtubeUri)) {
      await launchUrl(youtubeUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch YouTube link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFF6F7FB);
    const Color deepBlue = Color(0xFF103C57);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: pageBg,
        elevation: 0,
        title: CustomText(
          'Support',
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.headset_mic,
                            color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              "We're here to help",
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 4),
                            CustomText(
                              "Reach us anytime for account or order support.",
                              fontSize: 13.sp,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.white70),
                        const SizedBox(width: 8),
                        CustomText(
                          "Avg. response time: < 10 mins",
                          color: Colors.white,
                          fontSize: 13.sp,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CustomText(
              "Contact options",
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: deepBlue,
            ),
            const SizedBox(height: 10),
            _SupportTile(
              icon: Icons.email_rounded,
              title: "Email support",
              subtitle: "support@retildapropertyenterprise.com",
              onTap: _launchEmail,
            ),
            _SupportTile(
              icon: Icons.chat_rounded,
              title: "Chat on WhatsApp",
              subtitle: "+234 806 193 1283",
              onTap: _launchWhatsApp,
            ),
            _SupportTile(
              icon: Icons.call,
              title: "Call support",
              subtitle: "Tap to dial our care line",
              onTap: _launchCall,
            ),
            _SupportTile(
              icon: Icons.shopping_bag,
              title: "Purchase guide",
              subtitle: "Watch a quick walkthrough",
              onTap: () => _launchGuide(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ROrange.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: ROrange),
        ),
        title: CustomText(
          title,
          fontSize: 14.sp,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF103C57),
        ),
        subtitle: CustomText(
          subtitle,
          fontSize: 12.sp,
          color: Colors.grey[700],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black54),
      ),
    );
  }
}
