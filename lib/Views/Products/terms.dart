import 'package:flutter/material.dart';



class TermsAndPolicyPage extends StatelessWidget {

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms'),
        actions: [
          GestureDetector(
            onTap: () {
              // Add your use case logic here
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  "Use case",
                  style: TextStyle(fontSize: 20, color: Colors.blue),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RETTILDA PROPERTY ENTERPRISE TERMS AND CONDITIONS:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Welcome to the Retilda Property Enterprise Web App. By using our app, you agree to comply with and be bound by the following terms and conditions. Please read them carefully.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black),
                  children: [
                    TextSpan(
                      text: 'Acceptance of Terms:\n',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: 'These Terms and Conditions govern your access to and use of the Retilda Property Enterprise website and mobile application ("the Platform"). By accessing or using the Platform, you agree to be bound by these terms in full. If you do not agree to these terms, you must refrain from accessing or using the Platform.\n\n',
                    ),
                    TextSpan(
                      text: 'Services Offered:\n',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: 'The Platform provides access to electronic and household equipment, including but not limited to appliances, gadgets, and accessories. Users may browse, purchase, and/or inquire about products and services offered by Retilda Property Enterprise through the Platform. This platform provides a “Buy Now, Pay Later” (BNPL) option for eligible customers and account management and order tracking.\n\n',
                    ),
                    TextSpan(
                      text: 'User Accounts:\n',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: '● Account Creation: Users must provide accurate and current information during registration.\n',
                    ),
                    TextSpan(
                      text: '● Account Responsibility: You are responsible for maintaining the confidentiality of your account credentials and for all activities under your account.\n',
                    ),
                    TextSpan(
                      text: '● Account Termination: Retilda Property Enterprise reserves the right to suspend or terminate accounts for any violations of these terms.\n\n',
                    ),
                    TextSpan(
                      text: 'Eligibility Criteria:\n',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: 'To qualify for subscription into the Installment Plan, a buyer must meet the following conditions:\n',
                    ),
                    TextSpan(
                      text: '1. Registration as a buyer with Retilda Property Enterprise.\n',
                    ),
                    TextSpan(
                      text: '2. Attainment of 18 years of age or older.\n',
                    ),
                    TextSpan(
                      text: '3. Ability to enter into a legally binding contract.\n',
                    ),
                    TextSpan(
                      text: '4. Must be a Nigerian citizen and resides in Nigeria.\n',
                    ),
                    TextSpan(
                      text: '5. Provision of a valid delivery address within Nigeria.\n',
                    ),
                    TextSpan(
                      text: '6. Residency or employment at an electronically verifiable address.\n',
                    ),
                    TextSpan(
                      text: '7. Possession of a valid and verifiable email address and mobile telephone number.\n',
                    ),
                    TextSpan(
                      text: '8. Registration and electronic verification of any of the following:\n',
                    ),
                    TextSpan(
                      text: '   ● National Identification Card displaying the National Identification Number (NIN) of the holder.\n',
                    ),
                    TextSpan(
                      text: '   ● Bank Verification Number (BVN).\n',
                    ),
                    TextSpan(
                      text: '9. Authorization as a holder of an eligible Naira debit/MasterCard or another valid payment card, with the authority to utilize the provided payment method.\n',
                    ),
                    TextSpan(
                      text: '10. Consent to the addition of payment card details to the account for payment automation.\n\n',
                    ),
                    TextSpan(
                      text: 'Payment Terms:\n',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: '● Payments made via the app are subject to verification.\n',
                    ),
                    TextSpan(
                      text: '● BNPL users must adhere to the agreed payment schedule. Late or missed payments may attract penalties as stated in your agreement.\n',
                    ),
                    TextSpan(
                      text: '● All prices listed on the app are subject to change without prior notice.\n\n',
                    ),
                    // Continue adding the rest of the terms here...
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'DISCLAIMER:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Retilda Property Enterprise does not engage in manufacturing any products whatsoever. Therefore, no items listed in the Retilda Property Enterprise Catalogue have been manufactured, produced, or assembled by Retilda Property Enterprise. Retilda Property Enterprise will not be held liable to any buyer(s) for errors, defects, or damages incurred as a result of using or coming into contact with any such items purchased from Retilda Property Enterprise. The descriptions of all items listed in the Retilda Property Enterprise catalogue are provided by the respective manufacturers, who are responsible for any errors, defects, or damages suffered by users according to their individual terms and conditions of liability.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
