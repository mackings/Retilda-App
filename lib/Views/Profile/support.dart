
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';



class Support extends StatefulWidget {
  const Support({super.key});

  @override
  State<Support> createState() => _SupportState();
}

class _SupportState extends State<Support> {

  // Function to open the email client
Future<void> _launchEmail() async {
  final Uri emailLaunchUri = Uri(
    scheme: 'mailto',
    path: 'support@retildapropertyenterprise.com',
    query: Uri.encodeQueryComponent('Hello, I need help with...')
  );
  if (await canLaunchUrl(emailLaunchUri)) {
    await launchUrl(emailLaunchUri);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not launch email client'))
    );
  }
}




  // Function to launch WhatsApp
 Future<void> _launchWhatsApp() async {
  final Uri whatsappLaunchUri = Uri.parse("https://wa.me/2348061931283");
  if (await canLaunchUrl(whatsappLaunchUri)) {
    await launchUrl(whatsappLaunchUri);
  } else {
    // If the above doesn't work, try using the direct WhatsApp scheme
    final String whatsappScheme = "whatsapp://send?phone=2348061931283";
    final Uri whatsappUri = Uri.parse(whatsappScheme);
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch WhatsApp'))
      );
    }
  }
}


  // Function to make a call
  Future<void> _launchCall() async {
    final Uri callLaunchUri = Uri.parse("tel:+2348061931283");
    if (await canLaunchUrl(callLaunchUri)) {
      await launchUrl(callLaunchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not make the call'))
      );
    }
  }


Future<void> _launchGuide(BuildContext context) async {
  final Uri youtubeUri = Uri.parse("https://youtu.be/DNpEHq_WKvQ?feature=shared");

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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Support',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Support Email Button
            Card(
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.email),
                title: Text("Email Support"),
                onTap: _launchEmail,
              ),
            ),
            SizedBox(height: 16),

            // WhatsApp Button
            Card(
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.chat),
                title: Text("Chat on WhatsApp"),
                onTap: _launchWhatsApp,
              ),
            ),
            SizedBox(height: 16),

            // Call Support Button
            Card(
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.call),
                title: Text("Call Support"),
                onTap: _launchCall,
              ),
            ),

             SizedBox(height: 16),

Card(
  elevation: 4,
  child: ListTile(
    leading: const Icon(Icons.shopping_bag),
    title: const Text("Purchase Guide"),
    onTap: () {
      _launchGuide(context); 
    },
  ),
),


          ],
        ),
      ),
    );
  }
}
