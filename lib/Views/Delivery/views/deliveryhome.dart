
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retilda/Views/Delivery/Api/deliveryservice.dart';
import 'package:retilda/Views/Delivery/model/deliverymodel.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:sizer/sizer.dart';


class DeliveryDashboard extends StatefulWidget {
  @override
  _DeliveryDashboardState createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  final ApiService apiService = ApiService();
  late Future<DuePaymentResponse> _duePaymentsFuture;
  String? token; // Variable to store the token
  String _statusFilter = 'all';

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
        Uri.parse("https://retildaserver.vercel.app/Api/updatedPurchasesForDeliveryCompleted/$id"),
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
    const Color pageBg = Color(0xFFF6F7FB);
    return Sizer(builder: (context, orientation, deviceType) {
      return Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          backgroundColor: pageBg,
          elevation: 0,
          title: CustomText(
            'Delivery Center',
            fontWeight: FontWeight.w800,
            fontSize: 13.sp,
            color: RButtoncolor,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              color: RButtoncolor,
              onPressed: _fetchDuePayments,
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: FutureBuilder<DuePaymentResponse>(
          future: _duePaymentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                  child: CustomText(
                'Error: ${snapshot.error}',
                color: Colors.red,
              ));
            } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
              return Center(
                  child: CustomText(
                'No deliveries available.',
                color: Colors.grey[700],
              ));
            } else {
              final payments = snapshot.data!.data;
              final sortedPayments = payments
                ..sort((a, b) {
                  if (a.deliveryStatus == 'processing' &&
                      b.deliveryStatus != 'processing') {
                    return -1;
                  } else if (a.deliveryStatus != 'processing' &&
                      b.deliveryStatus == 'processing') {
                    return 1;
                  } else {
                    return 0;
                  }
                });
              final filteredPayments = sortedPayments.where((payment) {
                if (_statusFilter == 'all') return true;
                return payment.deliveryStatus == _statusFilter;
              }).toList();

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [RButtoncolor, const Color(0xFF145E8D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.16),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white24, width: 1),
                              ),
                              child: const Icon(Icons.local_shipping_rounded,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    'Live deliveries',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.sp,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 6),
                                  CustomText(
                                    'Track progress, complete drops, and confirm payments.',
                                    color: Colors.white70,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.22)),
                              ),
                              child: CustomText(
                                '${sortedPayments.length}',
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _FilterChip(
                            label: 'All',
                            selected: _statusFilter == 'all',
                            onTap: () {
                              setState(() {
                                _statusFilter = 'all';
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Processing',
                            selected: _statusFilter == 'processing',
                            onTap: () {
                              setState(() {
                                _statusFilter = 'processing';
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Completed',
                            selected: _statusFilter == 'completed',
                            onTap: () {
                              setState(() {
                                _statusFilter = 'completed';
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: filteredPayments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final payment = filteredPayments[index];
                          final bool isProcessing =
                              payment.deliveryStatus == 'processing';
                          final Color statusColor =
                              isProcessing ? ROrange : Colors.green;
                          final String buyerName =
                              payment.user?.fullName ?? 'Unknown User';
                          final String productName = payment.product.name;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 14,
                                  offset: const Offset(0, 10),
                                )
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          RButtoncolor.withOpacity(0.12),
                                      child: const Icon(Icons.person,
                                          color: Colors.black87),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CustomText(
                                            buyerName,
                                            fontWeight: FontWeight.w800,
                                           
                                          ),
                                          CustomText(
                                            fontSize: 12,
                                            payment.user?.email ??
                                                'No email provided',
                                            color: Colors.grey[700],
                                          
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isProcessing
                                                ? Icons.av_timer
                                                : Icons.check_circle,
                                            size: 16,
                                            color: statusColor,
                                          ),
                                          const SizedBox(width: 6),
                                          CustomText(
                                            payment.deliveryStatus
                                                .toUpperCase(),
                                            fontWeight: FontWeight.w800,
                                            color: statusColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: pageBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color:
                                              ROrange.withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                            Icons.shopping_bag_outlined,
                                            color: Colors.black87),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CustomText(
                                              productName,
                                              fontWeight: FontWeight.w700,
                                            //  maxLines: 1,
                                             // overflow: TextOverflow.ellipsis,
                                            ),
                                            CustomText(
                                              "Due payment: ${payment.duePaymentCompleted ? 'Cleared' : 'Pending'}",
                                              color: payment.duePaymentCompleted
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isProcessing)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.checklist_rtl,
                                            color: Colors.black87,
                                          ),
                                          onPressed: () =>
                                              _updateDeliveryStatus(
                                                  payment.id),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    _QuickAction(
                                      icon: Icons.call,
                                      label: 'Call',
                                      onTap: () {
                                        if (payment.user?.phone != null) {
                                          Clipboard.setData(ClipboardData(
                                              text: payment.user!.phone));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'Phone number copied!')));
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 10),
                                    _QuickAction(
                                      icon: Icons.email_outlined,
                                      label: 'Email',
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(
                                            text: payment.user?.email ?? ''));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content:
                                                    Text('Email copied!')));
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      );
    });
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: RButtoncolor),
              const SizedBox(width: 6),
              CustomText(
                label,
                fontWeight: FontWeight.w700,
                color: RButtoncolor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? ROrange.withOpacity(0.14) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? ROrange : Colors.grey.shade300, width: 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: ROrange.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list,
              size: 16,
              color: selected ? ROrange : Colors.grey[700],
            ),
            const SizedBox(width: 6),
            CustomText(
              label,
              fontWeight: FontWeight.w700,
              color: selected ? ROrange : Colors.grey[800],
            ),
          ],
        ),
      ),
    );
  }
}
