import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Admin/views/glance.dart';
import 'package:retilda/Views/Auth/Signup.dart';
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
import 'package:retilda/Views/Staff/views/active_staff_screen.dart';
import 'package:retilda/Views/Admin/views/admin_order_update_screen.dart';
import 'package:retilda/Views/Admin/views/admin_invoices_screen.dart';
import 'package:retilda/Views/Admin/views/admin_create_invoice_screen.dart';
import 'package:retilda/Views/Admin/views/admin_create_staff_screen.dart';
import 'package:retilda/Views/Geo/views/geo_admin_states_screen.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/profiletile.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/core/network/api_client.dart';
import 'package:retilda/core/presentation/widgets/dialogs.dart';
import 'package:retilda/core/security/app_session.dart';
import 'package:retilda/core/theme/app_theme.dart';
import 'package:sizer/sizer.dart';

class Profile extends ConsumerStatefulWidget {
  const Profile({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<Profile> {
  String? username;
  String? accountType;
  int? credit;
  String? role;
  String? refferalCode;
  int? refferalBonus;
  late final AppSession _session = AppSession();
  late final ApiClient _apiClient = ApiClient(session: _session);

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

  Future<void> _logout() async {
    await _session.clearStaffSession();
    await _session.clearUserSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Signup()),
      (route) => false,
    );
  }

  Future<void> _loadUserData() async {
    final userData = await _session.userData();
    final storedUserRole = await _session.userRole();
    final staffToken = await _session.staffToken();
    if (userData != null) {
      final user = userData['data']?['user'] as Map<String, dynamic>?;
      final loadedUsername = user?['fullName'] as String?;
      final loadedAccountType = user?['accountType'] as String?;
      final loadedCredit = _readInt(user?['creditScore']);
      final myrole = _extractRole(user?['roles']);
      final mycode = user?['referralCode'] as String?;
      final mybonus = _readInt(user?['referralBonus']);

      setState(() {
        username = loadedUsername;
        credit = loadedCredit;
        accountType = loadedAccountType;
        role = myrole ?? storedUserRole;
        refferalCode = mycode;
        refferalBonus = mybonus;
      });
      return;
    }

    setState(() {
      role = staffToken != null ? 'staff' : 'user';
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
          color: AppTheme.ink,
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
                    color: Colors.black.withValues(alpha: 0.08),
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
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        child: Icon(Icons.person,
                            color: Colors.white, size: 26.sp),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              username ?? (isPrivileged ? "Staff" : "User"),
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
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.shield_rounded,
                                          color: Colors.white, size: 16),
                                      const SizedBox(width: 6),
                                      CustomText(
                                        '${(accountType ?? "Standard") == "premium" ? "Premium" : "Standard"} Account',
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
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.grade,
                                          color: Colors.amber.shade300,
                                          size: 16),
                                      const SizedBox(width: 6),
                                      CustomText(
                                        'Score ${credit ?? 0}',
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
                      color: Colors.white.withValues(alpha: 0.1),
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
                              showAppSnackBar(
                                context,
                                message: 'Referral code copied',
                                tone: AppFeedbackTone.success,
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
                    color: Colors.black.withValues(alpha: 0.05),
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
                            color: AppTheme.ink,
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
                              final response = await _apiClient.put(
                                'moveReferralBonus',
                                body: {
                                  "referralBonus": refferalBonus.toString(),
                                },
                              );

                              if (!mounted || !context.mounted) return;
                              if (response.statusCode == 200) {
                                final responseData = json.decode(response.body);
                                if (responseData['success'] == true) {
                                  showAppAlert(
                                    context: context,
                                    title: 'Bonus moved',
                                    message:
                                        'Referral bonus redeemed successfully.',
                                    tone: AppFeedbackTone.success,
                                    buttonText: 'Continue',
                                  );
                                  setState(() {
                                    refferalBonus = 0;
                                  });
                                } else {
                                  showAppAlert(
                                    context: context,
                                    title: 'Redeem failed',
                                    message: responseData['message'] ??
                                        'Failed to redeem.',
                                    tone: AppFeedbackTone.error,
                                    buttonText: 'Okay',
                                  );
                                }
                              } else {
                                showAppAlert(
                                  context: context,
                                  title: 'Redeem failed',
                                  message:
                                      'Failed to redeem. Please try again.',
                                  tone: AppFeedbackTone.error,
                                  buttonText: 'Okay',
                                );
                              }
                            } catch (e) {
                              if (!mounted || !context.mounted) return;
                              showAppAlert(
                                context: context,
                                title: 'Redeem failed',
                                message: 'An error occurred: $e',
                                tone: AppFeedbackTone.error,
                                buttonText: 'Okay',
                              );
                            }
                          } else {
                            showAppSnackBar(
                              context,
                              message: 'No referral bonus to redeem.',
                              tone: AppFeedbackTone.warning,
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
              "Account hub",
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
                    subtitle: 'Verify your identity with BVN',
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => KYC()));
                    },
                  ),
                  ProfileListItem(
                    icon: Icons.policy_rounded,
                    title: 'Terms and Policy',
                    subtitle: 'Review Retilda usage and data policies',
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
                    subtitle: 'Get help from the Retilda team',
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
                      subtitle: 'Follow your active product deliveries',
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
                    subtitle: 'View payment requests and receipts',
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
                    subtitle: 'Choose how Retilda should alert you',
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
                    subtitle: 'Message support and staff members',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatThreadsScreen(),
                        ),
                      );
                    },
                  ),
                  if (isPrivileged) const _ProfileMenuLabel('Staff tools'),
                  if (isPrivileged)
                    ProfileListItem(
                      icon: Icons.people_outline,
                      title: 'Active staff',
                      subtitle: 'See support staff currently available',
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
                      subtitle: 'Manage customer order progress',
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
                  if (isAdmin) const _ProfileMenuLabel('Admin tools'),
                  if (isAdmin)
                    ProfileListItem(
                      icon: Icons.receipt_long,
                      title: 'Admin invoices',
                      subtitle: 'Review invoice activity across users',
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
                      subtitle: 'Generate a payment request',
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
                      subtitle: 'Add a staff login to Retilda',
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
                      subtitle: 'Configure delivery state coverage',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GeoAdminStatesScreen(),
                          ),
                        );
                      },
                    ),
                  if (isAdmin)
                    ProfileListItem(
                      icon: Icons.space_dashboard_outlined,
                      title: 'Merchant',
                      subtitle: 'Upload products to the catalogue',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const UploadProducts()),
                        );
                      },
                    ),
                  if (isAdmin)
                    ProfileListItem(
                      icon: Icons.system_update_alt,
                      title: 'Update Product',
                      subtitle: 'Edit existing product listings',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Producupdate()),
                        );
                      },
                    ),
                  if (isAdmin)
                    ProfileListItem(
                      icon: Icons.bike_scooter,
                      title: 'Delivery Center',
                      subtitle: 'Manage delivery operations',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DeliveryDashboard()),
                        );
                      },
                    ),
                  if (isAdmin)
                    ProfileListItem(
                      icon: Icons.dashboard,
                      title: 'At a Glance',
                      subtitle: 'View key activity and performance',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Glace()),
                        );
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
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await showAppNoticeSheet<void>(
                    context: context,
                    title: 'Log out',
                    message:
                        'You will be signed out of this device and returned to the login screen.',
                    tone: AppFeedbackTone.warning,
                    primaryLabel: 'Log out',
                    secondaryLabel: 'Cancel',
                    icon: Icons.logout_rounded,
                    onPrimaryPressed: () {
                      Navigator.of(context).pop();
                      _logout();
                    },
                    onSecondaryPressed: () => Navigator.of(context).pop(),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB42318),
                  side: const BorderSide(color: Color(0xFFF1B7B0)),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: Colors.white,
                ),
                icon: const Icon(Icons.logout_rounded),
                label: Text(
                  'Log out',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuLabel extends StatelessWidget {
  const _ProfileMenuLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 6),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: CustomText(
              label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black.withValues(alpha: 0.48),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}
