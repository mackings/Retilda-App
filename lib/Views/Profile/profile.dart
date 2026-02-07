import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Admin/views/glance.dart';
import 'package:retilda/Views/Auth/kyc.dart';
import 'package:retilda/Views/Delivery/views/deliveryhome.dart';
import 'package:retilda/Views/Merchant/upload.dart';
import 'package:retilda/Views/Products/Update/ProducUpdate.dart';
import 'package:retilda/Views/Products/terms.dart';
import 'package:retilda/Views/Profile/support.dart';
import 'package:retilda/Views/OrderTracking/views/order_tracking_list_screen.dart';
import 'package:retilda/Views/Invoices/views/invoices_screen.dart';
import 'package:retilda/Views/Notifications/views/notification_settings_screen.dart';
import 'package:retilda/Views/Chat/views/chat_threads_screen.dart';
import 'package:retilda/Views/Staff/views/staff_login_screen.dart';
import 'package:retilda/Views/Staff/views/active_staff_screen.dart';
import 'package:retilda/Views/Admin/views/admin_order_update_screen.dart';
import 'package:retilda/Views/Admin/views/admin_invoices_screen.dart';
import 'package:retilda/Views/Admin/views/admin_create_invoice_screen.dart';
import 'package:retilda/Views/Admin/views/admin_create_staff_screen.dart';
import 'package:retilda/Views/Geo/views/geo_admin_states_screen.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/profiletile.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;

class Profile extends ConsumerStatefulWidget {
  const Profile({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<Profile> {
  String? Token;
  String? Username;
  String? Acctype;
  int? Credit;
  String? role;
  String? refferalCode;
  int? refferalBonus;

  String? _extractRole(dynamic rawRoles) {
    if (rawRoles == null) return null;
    if (rawRoles is String) {
      final value = rawRoles.trim().toLowerCase();
      return value.isEmpty ? null : value;
    }
    if (rawRoles is List) {
      final roles = rawRoles
          .whereType<String>()
          .map((value) => value.trim().toLowerCase())
          .where((value) => value.isNotEmpty)
          .toList();
      if (roles.contains('admin')) return 'admin';
      if (roles.contains('staff')) return 'staff';
      if (roles.contains('user')) return 'user';
      return roles.isNotEmpty ? roles.first : null;
    }
    return null;
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<void> _loadUserData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userDataString = sharedPreferences.getString('userData');
    final storedUserRole = sharedPreferences.getString('userRole');
    final storedStaffRole = sharedPreferences.getString('staffRole');
    final storedStaffData = sharedPreferences.getString('staffData');
    final staffToken = sharedPreferences.getString('staffToken');
    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      final token = userData['data']?['token'] as String?;
      final user = userData['data']?['user'] as Map<String, dynamic>?;
      final username = user?['fullName'] as String?;
      final accttype = user?['accountType'] as String?;
      final credit = _readInt(user?['creditScore']);
      final myrole = _extractRole(user?['roles']);
      final mycode = user?['referralCode'] as String?;
      final mybonus = _readInt(user?['referralBonus']);

      setState(() {
        Token = token;
        Username = username;
        Credit = credit;
        Acctype = accttype;
        role = myrole ?? storedUserRole;
        refferalCode = mycode;
        refferalBonus = mybonus;
      });
      return;
    }

    if (storedStaffData != null) {
      final staff = jsonDecode(storedStaffData) as Map<String, dynamic>;
      setState(() {
        Username = staff['fullName'] as String?;
        role = storedStaffRole ?? 'staff';
      });
      return;
    }

    setState(() {
      role = storedStaffRole ?? (staffToken != null ? 'staff' : 'user');
    });
  }

  @override
  void initState() {
    _loadUserData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFF6F7FB);
    const Color deepBlue = Color(0xFF103C57);
    final isAdmin = role == 'admin';
    final isStaff = role == 'staff';
    final isPrivileged = isAdmin || isStaff;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: pageBg,
        elevation: 0,
        title: CustomText(
          'Profile',
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        child: Icon(Icons.person,
                            color: Colors.white, size: 26.sp),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              Username ?? (isPrivileged ? "Staff" : "User"),
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.shield_rounded,
                                          color: Colors.white, size: 16),
                                      const SizedBox(width: 6),
                                      CustomText(
                                        '${(Acctype ?? "Standard") == "premium" ? "Premium" : "Standard"} Account',
                                        color: Colors.white,
                                        fontSize: 12.sp,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.grade,
                                          color: Colors.amber.shade300,
                                          size: 16),
                                      const SizedBox(width: 6),
                                      CustomText(
                                        'Score ${Credit ?? 0}',
                                        color: Colors.white,
                                        fontSize: 12.sp,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                'Referral Code',
                                color: Colors.white70,
                                fontSize: 11.sp,
                              ),
                              const SizedBox(height: 4),
                              CustomText(
                                refferalCode ?? "N/A",
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (refferalCode != null) {
                              Clipboard.setData(
                                  ClipboardData(text: refferalCode!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Referral Code Copied!")),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            'Referral Points',
                            fontSize: 12.sp,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(height: 4),
                          CustomText(
                            '${refferalBonus ?? "0"}',
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: deepBlue,
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ROrange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (refferalBonus != null && refferalBonus! > 0) {
                            try {
                              final response = await http.put(
                                Uri.parse(
                                    'https://retildaserver.vercel.app/Api/moveReferralBonus'),
                                headers: {
                                  'Content-Type': 'application/json',
                                  'Authorization': 'Bearer ${Token ?? ""}',
                                },
                                body: json.encode(
                                    {"referralBonus": refferalBonus.toString()}),
                              );

                              if (response.statusCode == 200) {
                                final responseData =
                                    json.decode(response.body);
                                if (responseData['success'] == true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "Referral bonus redeemed successfully!")),
                                  );
                                  setState(() {
                                    refferalBonus = 0;
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(responseData['message'] ??
                                            "Failed to redeem.")),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          "Failed to redeem. Please try again.")),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text("An error occurred: $e")),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("No referral bonus to redeem.")),
                            );
                          }
                        },
                        icon: const Icon(Icons.card_giftcard, size: 18),
                        label: const Text("Redeem"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CustomText(
                    "Earn more by sharing your code with friends.",
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            CustomText(
              "Quick Actions",
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: deepBlue,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [
                  ProfileListItem(
                    icon: Icons.check_circle,
                    title: 'KYC',
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => KYC()));
                    },
                  ),
                  ProfileListItem(
                    icon: Icons.policy_rounded,
                    title: 'Terms and Policy',
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TermsAndPolicyPage()));
                    },
                  ),
                  ProfileListItem(
                    icon: Icons.support_agent,
                    title: 'Support',
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Support()));
                    },
                  ),
                  if (!isPrivileged)
                    ProfileListItem(
                      icon: Icons.track_changes,
                      title: 'Order tracking',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const OrderTrackingListScreen(),
                          ),
                        );
                      },
                    ),
                  ProfileListItem(
                    icon: Icons.receipt_long,
                    title: 'Invoices',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InvoicesScreen(),
                        ),
                      );
                    },
                  ),
                  ProfileListItem(
                    icon: Icons.notifications_active_outlined,
                    title: 'Notifications',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  ProfileListItem(
                    icon: Icons.chat_bubble_outline,
                    title: 'Chat',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatThreadsScreen(),
                        ),
                      );
                    },
                  ),
                  if (isPrivileged)
                    ProfileListItem(
                      icon: Icons.people_outline,
                      title: 'Active staff',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ActiveStaffScreen(),
                          ),
                        );
                      },
                    ),
                  if (isPrivileged)
                    ProfileListItem(
                      icon: Icons.track_changes,
                      title: 'Update tracking',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AdminOrderUpdateScreen(),
                          ),
                        );
                      },
                    ),
                  if (isAdmin)
                    ProfileListItem(
                      icon: Icons.receipt_long,
                      title: 'Admin invoices',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminInvoicesScreen(),
                          ),
                        );
                      },
                    ),
                  if (isPrivileged)
                    ProfileListItem(
                      icon: Icons.post_add,
                      title: 'Create invoice',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AdminCreateInvoiceScreen(),
                          ),
                        );
                      },
                    ),
                  if (isAdmin)
                    ProfileListItem(
                      icon: Icons.person_add_alt_1,
                      title: 'Create staff',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AdminCreateStaffScreen(),
                          ),
                        );
                      },
                    ),
                  if (isAdmin)
                    ProfileListItem(
                      icon: Icons.location_city,
                      title: 'Manage states',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const GeoAdminStatesScreen(),
                          ),
                        );
                      },
                    ),
                  if (isAdmin)
                    ProfileListItem(
                      icon: Icons.space_dashboard_outlined,
                      title: 'Merchant',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const UploadProducts()),
                        );
                        print('Merchant tapped');
                      },
                    ),
                  if (isAdmin)
                    ProfileListItem(
                      icon: Icons.system_update_alt,
                      title: 'Update Product',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Producupdate()),
                        );
                        print('Merchant tapped');
                      },
                    ),
                  if (isAdmin)
                    ProfileListItem(
                      icon: Icons.bike_scooter,
                      title: 'Delivery Center',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                   DeliveryDashboard()),
                        );
                        print('Merchant tapped');
                      },
                    ),
                  if (isAdmin)
                    ProfileListItem(
                      icon: Icons.dashboard,
                      title: 'At a Glance',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Glace()),
                        );
                        print('Merchant tapped');
                      },
                    ),
                  // if (isPrivileged)
                  //   ProfileListItem(
                  //     icon: Icons.show_chart_rounded,
                  //     title: 'Sales',
                  //     onTap: () {
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(builder: (context) => Glace()),
                  //       );
                  //     },
                  //   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
