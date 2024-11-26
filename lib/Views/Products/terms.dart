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
              
            },
            child: Text("Use case",
          style: TextStyle(fontSize: 20,color: Colors.blue),))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black),
                  children: [
                    TextSpan(
                      text: '1. Payment Terms\n',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '● BNPL users must adhere to agreed schedules. Late payments will incur penalties.\n'),
                    TextSpan(text: '● Prices are subject to change without notice.\n\n'),

                    TextSpan(
                      text: '2. Product Availability\n',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '● Products are subject to availability. Prices and offers may change without prior notice.\n\n'),

                    TextSpan(
                      text: '3. Installment Plans\n',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '● Payments depend on product value, ranging from 1 month to 1 year.\n'),
                    TextSpan(text: '● At least 60% of the payment must be made by the midpoint of the plan for delivery.\n\n'),

                    TextSpan(
                      text: '4. Shipping and Delivery\n',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '● Delivery takes up to 10 working days from the plan\'s midpoint if 60% payment is complete.\n'),
                    TextSpan(text: '● Defaulting on payments delays delivery until full payment is made.\n\n'),

                    TextSpan(
                      text: '5. Returns and Refunds\n',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '● Items cannot be swapped for cash; 20% will be deducted for cancellations.\n'),
                    TextSpan(text: '● Delivered items cannot be exchanged.\n\n'),

                    TextSpan(
                      text: '6. Late Fees\n',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '● A grace period applies: 7 days for monthly and 3 days for weekly payments. After that, late fees of 10% (monthly) or 2.5% (weekly) are charged.\n\n'),

                    TextSpan(
                      text: '7. Defaulting and Recovery\n',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '● Defaulting users must return items.\n'),
                    TextSpan(text: '● Retilda may retrieve items directly if necessary.\n\n'),

                    TextSpan(
                      text: '8. Disclaimer\n',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: 'Retilda does not manufacture products. Any product issues are the responsibility of the manufacturer.\n'),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Privacy Policy Title
              Text(
                'Privacy Policy',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),

              // Privacy Policy Content
              Text(
                '''
The privacy policy section can detail how user data is collected, stored, and shared. You can replace this with the actual privacy policy text relevant to your application.
                ''',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
