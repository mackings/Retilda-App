import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Admin/Api/service.dart';
import 'package:retilda/Views/Admin/model/model.dart';
import 'package:retilda/Views/Admin/views/pending.dart';
import 'package:retilda/Views/Admin/widgets/purchasemodal.dart';


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
      });
    } catch (e) {
      print('Error calculating total paid: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Sales Dashboard',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
             // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sales ',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
Text(
  '₦${NumberFormat("#,##0.00", "en_NG").format(_totalPaid)}',
  style: GoogleFonts.poppins(fontSize: 15),
),

              ],
            ),
            actions: [
IconButton(
  icon: Icon(Icons.pending_actions),
  onPressed: () {
    // No fetching here — page will handle loading
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PendingPaymentsPage(users: _allUsers),
      ),
    );
  },
),


  ],
          ),
          body: Padding(
            padding: const EdgeInsets.only(left: 20,right: 20,top: 30),
            child: Column(
              children: [
                // Search bar
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(width: 0.5,color: Colors.black)
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      border: InputBorder.none,
                      icon: Icon(Icons.search),
                    ),
                    style: GoogleFonts.poppins(),
                  ),
                ),
                SizedBox(height: 12),
                Expanded(
                  child: _filteredUsers.isEmpty
                      ? Center(
                          child: Text(
                            'No users found',
                            style: GoogleFonts.poppins(),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 6),
                              padding: EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.blue,
                                  ),
                                ),
                                title: Text(
                                  user.fullName,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.email,
                                      style: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                    Text(
                                      user.phone,
                                      style: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                  ],
                                ),
                                trailing: Icon(Icons.arrow_forward_ios),
                                onTap: () async {
                                  try {
                                    final userPurchases =
                                        await ApiService.fetchUserPurchases(user.id);

                                    if (userPurchases.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                '${user.fullName} has no purchases')),
                                      );
                                      return;
                                    }

                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => PurchaseDetailsModal(
                                        purchases: userPurchases,
                                        user: user,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$e')),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

