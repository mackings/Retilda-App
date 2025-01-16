import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';












class DeliveryModal extends StatefulWidget {
  final String purchaseId;

  DeliveryModal({required this.purchaseId});

  @override
  _DeliveryModalState createState() => _DeliveryModalState();
}

class _DeliveryModalState extends State<DeliveryModal> {
  final _addressController = TextEditingController();
  final _dateController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  final List<String> _timeSlots = [
    '08:00 AM - 10:00 AM',
    '10:00 AM - 12:00 PM',
    '12:00 PM - 02:00 PM',
    '02:00 PM - 04:00 PM',
    '04:00 PM - 06:00 PM',
    '06:00 PM - 08:00 PM'
  ];
  final List<String> _categories = ['local', 'regional', 'interstate'];
  String? _selectedTimeSlot;
  String? _selectedCategory;
  bool isLoading = false;
  String? token;
  int? deliveryFee;
  bool isQuotationFetched = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userDataString = sharedPreferences.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      setState(() {
        token = userData['data']['token'];
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }




Future<void> _fetchQuotation() async {
  if (token == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to fetch user token.')),
    );
    return;
  }

  if (_addressController.text.isEmpty ||
      _phoneNumberController.text.isEmpty ||
      _dateController.text.isEmpty ||
      _selectedTimeSlot == null ||
      _selectedCategory == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please fill all the fields.')),
    );
    return;
  }

  setState(() => isLoading = true);

  final url =
      'https://retilda-fintech.vercel.app/Api/requestForGoodsDeliveryCalculation/${widget.purchaseId}';

  final body = {
    "deliveryAddress": _addressController.text,
    "phoneNumber": _phoneNumberController.text,
    "deliveryTime": _selectedTimeSlot,
    "deliveryDate": _dateController.text,
    "category": _selectedCategory,
    "distance": _selectedCategory,
  };

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

if (response.statusCode == 200) {
  final data = jsonDecode(response.body);

  // Log the response for debugging
  print("API Response: ${data}");

  setState(() {
    // Access the deliveryFee field inside the data object
    deliveryFee = data['data']['deliveryFee']; 
    isQuotationFetched = true;
  });
} else {
  final error = jsonDecode(response.body)['message'] ?? 'Quotation failed.';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Failed: $error')),
  );
}

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred: $e')),
    );
  } finally {
    setState(() => isLoading = false);
  }
}



  Future<void> _requestDelivery() async {
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to fetch user token.')),
      );
      return;
    }

    final url =
        'https://retilda-fintech.vercel.app/Api/requestForGoodsDelivery/${widget.purchaseId}';

    final body = {

      "deliveryAddress": _addressController.text,
      "phoneNumber": _phoneNumberController.text,
      "deliveryTime": _selectedTimeSlot,
      "deliveryDate": _dateController.text,
      "category": _selectedCategory,
      "distance": _selectedCategory,
    };


    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print("Delivery Request sent");
        print(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delivery requested successfully.')),
        );
        Navigator.pop(context);
      } else {
        print(response.body);
        Navigator.pop(context);
        final error = jsonDecode(response.body)['message'] ?? 'Request failed.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close),
                  ),
                ),
                SizedBox(height: 15),

                Row(
                  children: [
                    Text(
                      "Your Item Delivery",
                      style: GoogleFonts.poppins(
                          fontSize: 12.sp, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.location_history),
                  ],
                ),

                Text("Your Delivery arrives in 2 weeks from the request date."),
                SizedBox(height: 25),
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Enter Delivery Address",
                  ),
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _phoneNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Enter Phone Number",
                  ),
                ),
                SizedBox(height: 16.0),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Select Delivery Date",
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Select Time Slot",
                  ),
                  value: _selectedTimeSlot,
                  items: _timeSlots.map((slot) {
                    return DropdownMenuItem(
                      value: slot,
                      child: Text(slot),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTimeSlot = value;
                    });
                  },
                ),
                SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Select Category",
                  ),
                  value: _selectedCategory,
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
                SizedBox(height: 20),
                if (deliveryFee != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Delivery Fee:",
                        style: GoogleFonts.montserrat()
                      ),

                                            Text(
                        "₦ $deliveryFee",
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp
                        )
                      ),
                    ],
                  ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);
                          if (isQuotationFetched) {
                            // Request Delivery API
                            await _requestDelivery();
                          } else {
                            // Fetch Quotation API
                            await _fetchQuotation();
                          }
                          setState(() => isLoading = false);
                        },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 15.0),
                    decoration: BoxDecoration(
                      color: ROrange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isQuotationFetched
                                  ? "Request Delivery"
                                  : "View Delivery Quotation",
                              style:
                                  GoogleFonts.montserrat(color: Colors.white),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _dateController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }
}
