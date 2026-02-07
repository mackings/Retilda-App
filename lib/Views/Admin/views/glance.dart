import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Admin/Api/service.dart';
import 'package:retilda/Views/Admin/model/model.dart';
import 'package:retilda/Views/Admin/views/pending.dart';
import 'package:retilda/Views/Admin/widgets/purchasemodal.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:sizer/sizer.dart';


class Glace extends StatefulWidget {
  const Glace({super.key});

  @override
  State<Glace> createState() => _GlaceState();
}





class _GlaceState extends State<Glace> {
  late Future<void> _initFuture;
  List<GlanceUser> _allUsers = [];
  List<GlanceUser> _filteredUsers = [];
  TextEditingController _searchController = TextEditingController();
  double _totalPaid = 0;
  Map<String, double> _userTotals = {};
  String _filterMode = 'all';

  @override
  void initState() {
    super.initState();
    _initFuture = _loadUsersAndTotal();

    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filteredUsers = _allUsers.where((user) {
          return user.fullName.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query);
        }).toList();
      });
    });
  }

  Future<void> _loadUsersAndTotal() async {
    try {
      // Load users first
      final users = await ApiService.fetchUsers();
      users.sort(
          (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));

      setState(() {
        _allUsers = users;
        _filteredUsers = users;
      });

      // Calculate total paid
      await _calculateTotalPaid(users);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _calculateTotalPaid(List<GlanceUser> users) async {
    try {
      double total = 0;

      // Fetch all user purchases in parallel
      final futures = users.map((user) async {
        try {
          final purchases = await ApiService.fetchUserPurchases(user.id);
          double userTotal = purchases.fold<double>(
              0,
              (sum, purchase) => sum +
                  purchase.payments.fold<int>(
                      0, (pSum, payment) => pSum + payment.amountPaid));
          return userTotal;
        } catch (e) {
          // Ignore users with no purchases
          return 0.0;
        }
      }).toList();

      final totals = await Future.wait(futures);

      total = totals.fold(0.0, (sum, t) => sum + t);

      setState(() {
        _totalPaid = total;
        _userTotals = Map.fromIterables(
          users.map((u) => u.id),
          totals,
        );
      });
    } catch (e) {
      print('Error calculating total paid: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFF6F7FB);
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: pageBg,
            appBar: AppBar(
              backgroundColor: pageBg,
              elevation: 0,
              title: CustomText(
                'Sales Dashboard',
                fontWeight: FontWeight.w800,
                color: RButtoncolor,
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final currencyTotal =
            'N${NumberFormat("#,##0.00", "en_NG").format(_totalPaid)}';

        final List<GlanceUser> displayedUsers = _filteredUsers.where((user) {
          if (_filterMode == 'all') return true;
          final total = _userTotals[user.id] ?? 0;
          if (_filterMode == 'high') return total >= 100000; // threshold
          if (_filterMode == 'zero') return total == 0;
          return true;
        }).toList();

        return Sizer(builder: (context, orientation, deviceType) {
          return Scaffold(
            backgroundColor: pageBg,
            appBar: AppBar(
              backgroundColor: pageBg,
              elevation: 0,
              title: CustomText(
                'Sales',
                fontWeight: FontWeight.w800,
                fontSize: 14.sp,
                color: RButtoncolor,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.pending_actions),
                  color: RButtoncolor,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PendingPaymentsPage(users: _allUsers),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            border:
                                Border.all(color: Colors.white24, width: 1),
                          ),
                          child: const Icon(Icons.show_chart_rounded,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                currencyTotal,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.sp,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 4),
                              CustomText(
                                '${_allUsers.length} customers',
                                color: Colors.white70,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.filter_alt_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              CustomText(
                                _filterMode == 'all'
                                    ? 'All'
                                    : _filterMode == 'high'
                                        ? 'Top spenders'
                                        : 'No spend',
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterPill(
                        label: 'All',
                        selected: _filterMode == 'all',
                        onTap: () {
                          setState(() => _filterMode = 'all');
                        },
                      ),
                      _FilterPill(
                        label: 'Spenders',
                        selected: _filterMode == 'high',
                        onTap: () {
                          setState(() => _filterMode = 'high');
                        },
                      ),
                      _FilterPill(
                        label: 'No spend',
                        selected: _filterMode == 'zero',
                        onTap: () {
                          setState(() => _filterMode = 'zero');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search name or email',
                        border: InputBorder.none,
                        icon: Icon(Icons.search),
                      ),
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  displayedUsers.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: CustomText(
                              'No users found',
                              color: Colors.grey[700],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayedUsers.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final user = displayedUsers[index];
                            final userTotal = _userTotals[user.id] ?? 0;
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 8),
                                  )
                                ],
                              ),
                              padding: const EdgeInsets.all(12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      RButtoncolor.withOpacity(0.12),
                                  child: const Icon(Icons.person,
                                      color: Colors.black87),
                                ),
                                title: CustomText(
                                  user.fullName,
                                  fontWeight: FontWeight.w700,
                                 // maxLines: 1,
                                 // overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      user.email,
                                      color: Colors.grey[700],
                                      fontSize: 12.sp,
                                    //  maxLines: 1,
                                    //  overflow: TextOverflow.ellipsis,
                                    ),
                                    CustomText(
                                      user.phone,
                                      color: Colors.grey[700],
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    CustomText(
                                      'N${NumberFormat("#,##0").format(userTotal)}',
                                      fontWeight: FontWeight.w800,
                                      color: RButtoncolor,
                                      fontSize: 15.sp,
                                    ),
                                    CustomText(
                                      'tap to view',
                                      color: Colors.grey[600],
                                      fontSize: 10.sp,
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  try {
                                    final userPurchases =
                                        await ApiService.fetchUserPurchases(
                                            user.id);

                                    if (userPurchases.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${user.fullName} has no purchases'),
                                        ),
                                      );
                                      return;
                                    }

                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) =>
                                          PurchaseDetailsModal(
                                        purchases: userPurchases,
                                        user: user,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(content: Text('$e')),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
            )
          );
        });
      },
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? ROrange.withOpacity(0.14) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? ROrange : Colors.grey.shade300, width: 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: ROrange.withOpacity(0.16),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_alt_outlined,
                size: 16, color: selected ? ROrange : Colors.grey[700]),
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
