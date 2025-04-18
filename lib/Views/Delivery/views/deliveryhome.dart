
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retilda/Views/Delivery/Api/deliveryservice.dart';
import 'package:retilda/Views/Delivery/model/deliverymodel.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class DeliveryDashboard extends StatefulWidget {
  @override
  _DeliveryDashboardState createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  final ApiService apiService = ApiService();
  late Future<DuePaymentResponse> _duePaymentsFuture;
  String? token; // Variable to store the token

  @override
  void initState() {
    super.initState();
    _fetchDuePayments();
    _loadUserData(); // Ensure user data is loaded when the screen initializes
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userDataString = sharedPreferences.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      String Token = userData['data']['token'];
      setState(() {
        token = Token;
        _fetchDuePayments(); // Reload payments after setting the token
      });

      print("User Token: $Token");
    }
  }

  // Fetch the due payments
  void _fetchDuePayments() {
    setState(() {
      _duePaymentsFuture = apiService.getAllDuePayments();
    });
  }

  // Update delivery status
  Future<void> _updateDeliveryStatus(String id) async {
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User is not authenticated')));
      return;
    }

    try {
      final response = await http.put(
        Uri.parse("https://retilda-fintech-3jy7.onrender.com/Api/updatedPurchasesForDeliveryCompleted/$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // Include the token in the request header
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delivery Status Updated!')));
        _fetchDuePayments(); // Refresh the data after updating
      } else {
        throw Exception('Failed to update delivery status');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  appBar: AppBar(
    title: Text('Delivery Overview', style: GoogleFonts.poppins()),
    actions: [
      IconButton(
        icon: Icon(Icons.refresh),
        onPressed: _fetchDuePayments,
      ),
    ],
  ),
  body: FutureBuilder<DuePaymentResponse>(
    future: _duePaymentsFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.poppins()));
      } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
        return Center(child: Text('No data available.', style: GoogleFonts.poppins()));
      } else {
        final payments = snapshot.data!.data;


        // Sort payments by deliveryStatus: 'processing' first, 'completed' later
        final sortedPayments = payments
            ..sort((a, b) {
              if (a.deliveryStatus == 'processing' && b.deliveryStatus != 'processing') {
                return -1; // 'processing' should come first
              } else if (a.deliveryStatus != 'processing' && b.deliveryStatus == 'processing') {
                return 1; // 'completed' should come after 'processing'
              } else {
                return 0; // If both are the same status, maintain the order
              }
            });


        return ListView.builder(
          itemCount: sortedPayments.length,
          itemBuilder: (context, index) {
            final payment = sortedPayments[index];
            return // In the ListView.builder's itemBuilder:
Padding(
  padding: const EdgeInsets.all(10.0),
  child: Card(
    margin: EdgeInsets.all(8.0),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  payment.user?.fullName ?? 'Unknown User', // Safely check for null
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.mail, color: Colors.red),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  payment.user?.email ?? 'No email provided', // Safely check for null
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.call, color: Colors.green),
              SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  if (payment.user?.phone != null) {
                    Clipboard.setData(ClipboardData(text: payment.user!.phone));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Phone number copied!')),
                    );
                  }
                },
                child: Text(
                  payment.user?.phone ?? 'No phone number available', // Safely check for null
                  style: GoogleFonts.poppins(decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8),

          Divider(),

          Row(
            children: [
              Icon(Icons.shopping_cart, color: Colors.purple),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  payment.product.name,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.local_shipping, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Status: ",
                      style: GoogleFonts.poppins(),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: payment.deliveryStatus == 'completed'
                                ? Colors.blue
                                : Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            payment.deliveryStatus.toUpperCase(),
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        ),
                        if (payment.deliveryStatus == 'processing')
                          IconButton(
                            icon: Icon(Icons.update_rounded, color: Colors.black),
                            onPressed: () => _updateDeliveryStatus(payment.id),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.teal),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Due Payment Completed: ${payment.duePaymentCompleted ? 'Cleared' : 'Pending'}",
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);

          },
        );
      }
    },
  ),
);

  }
}