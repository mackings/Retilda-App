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
        'https://retildaserver.vercel.app/Api/requestForGoodsDeliveryCalculation/${widget.purchaseId}';

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
        final bool tokenExpired = error.toLowerCase().contains('token has expired');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tokenExpired
                ? 'Session expired. Please log out and sign back in.'
                : 'Failed: $error'),
          ),
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
        'https://retildaserver.vercel.app/Api/requestForGoodsDelivery/${widget.purchaseId}';

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
        final bool tokenExpired = error.toLowerCase().contains('token has expired');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tokenExpired
                ? 'Session expired. Please log out and sign back in.'
                : 'Failed: $error'),
          ),
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
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Schedule Delivery",
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Arrives in ~2 weeks after request. Provide delivery details to get a fee estimate.",
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: "Delivery Address",
                        prefixIcon: const Icon(Icons.home_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _dateController,
                          decoration: InputDecoration(
                            labelText: "Delivery Date",
                            prefixIcon: const Icon(Icons.calendar_today_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelText: "Time Slot",
                      ),
                      value: _selectedTimeSlot,
                      items: _timeSlots
                          .map((slot) => DropdownMenuItem(
                                value: slot,
                                child: Text(slot),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedTimeSlot = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelText: "Category",
                      ),
                      value: _selectedCategory,
                      items: _categories
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedCategory = value),
                    ),
                    const SizedBox(height: 12),
                    if (deliveryFee != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Estimated Fee",
                                style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w500)),
                            Text("₦ $deliveryFee",
                                style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.sp)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                setState(() => isLoading = true);
                                if (isQuotationFetched) {
                                  await _requestDelivery();
                                } else {
                                  await _fetchQuotation();
                                }
                                setState(() => isLoading = false);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ROrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isQuotationFetched
                                    ? "Request Delivery"
                                    : "View Delivery Quotation",
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
