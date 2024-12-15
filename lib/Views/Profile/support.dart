
import 'package:flutter/material.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

class Support extends StatefulWidget {
  const Support({super.key});

  @override
  State<Support> createState() => _SupportState();
}

class _SupportState extends State<Support> {

  // Function to open the email client
  _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@retildapropertyenterprise.com',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      throw 'Could not launch email client';
    }
  }

  // Function to launch WhatsApp
  _launchWhatsApp() async {
    final Uri whatsappLaunchUri = Uri.parse("https://wa.me/2348061931283");
    if (await canLaunchUrl(whatsappLaunchUri)) {
      await launchUrl(whatsappLaunchUri);
    } else {
      throw 'Could not launch WhatsApp';
    }
  }

  // Function to make a call
  _launchCall() async {
    final Uri callLaunchUri = Uri.parse("tel:+2348061931283");
    if (await canLaunchUrl(callLaunchUri)) {
      await launchUrl(callLaunchUri);
    } else {
      throw 'Could not launch call';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: CustomText(
          'Support',
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Support Email Button
            ElevatedButton(
              onPressed: _launchEmail,
              child: Row(
                children: const [
                  Icon(Icons.email),
                  SizedBox(width: 8),
                  Text("Email Support"),
                ],
              ),
            ),
            SizedBox(height: 16),

            // WhatsApp Button
            ElevatedButton(
              onPressed: _launchWhatsApp,
              child: Row(
                children: const [
                  Icon(Icons.chat),
                  SizedBox(width: 8),
                  Text("Chat on WhatsApp"),
                ],
              ),
            ),
            SizedBox(height: 16),

            // App In Call Button
            ElevatedButton(
              onPressed: _launchCall,
              child: Row(
                children: const [
                  Icon(Icons.call),
                  SizedBox(width: 8),
                  Text("Call Support"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
