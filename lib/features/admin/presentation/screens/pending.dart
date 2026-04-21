import 'package:flutter/material.dart';
import 'package:retilda/Views/Admin/Api/service.dart';
import 'package:retilda/Views/Admin/model/model.dart';
import 'package:retilda/Views/Admin/widgets/purchasemodal.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:sizer/sizer.dart';

class PendingPaymentsPage extends StatefulWidget {
  final List<GlanceUser> users;

  const PendingPaymentsPage({super.key, required this.users});

  @override
  State<PendingPaymentsPage> createState() => _PendingPaymentsPageState();
}

class _PendingPaymentsPageState extends State<PendingPaymentsPage> {
  bool showCompleted = false;
  Map<String, List<GlancePurchase>> userPurchases = {};
  bool _loading = true;
  String _statusFilter = 'pending';
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    Map<String, List<GlancePurchase>> purchasesMap = {};

    final futures = widget.users.map((user) async {
      try {
        final purchases = await ApiService.fetchUserPurchases(user.id);
        purchasesMap[user.id] = purchases;
      } catch (_) {
        purchasesMap[user.id] = [];
      }
    }).toList();

    await Future.wait(futures);

    setState(() {
      userPurchases = purchasesMap;
      _loading = false;
    });
  }

  bool _isCompleted(List<GlancePurchase> purchases) {
    for (var purchase in purchases) {
      int totalPaid = purchase.payments.fold(0, (sum, p) => sum + p.amountPaid);
      if (totalPaid < purchase.product.price) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFF6F7FB);

    if (_loading) {
      return Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          backgroundColor: pageBg,
          elevation: 0,
          title: const Text('Payments'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final filteredUsers = widget.users.where((user) {
      final purchases = userPurchases[user.id] ?? [];
      final completed = _isCompleted(purchases);
      final matchesStatus =
          _statusFilter == 'completed' ? completed : !completed;
      final q = _searchController.text.toLowerCase();
      final matchesQuery = user.fullName.toLowerCase().contains(q) ||
          user.email.toLowerCase().contains(q);
      return matchesStatus && matchesQuery;
    }).toList();

    return Sizer(builder: (context, orientation, deviceType) {
      return Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          backgroundColor: pageBg,
          elevation: 0,
          title: CustomText(
            'Payments',
            fontWeight: FontWeight.w800,
            fontSize: 14.sp,
            color: RButtoncolor,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  CustomText(
                    _statusFilter == 'completed' ? 'Completed' : 'Pending',
                    color: RButtoncolor,
                  ),
                  Switch(
                    value: _statusFilter == 'completed',
                    activeColor: ROrange,
                    onChanged: (val) {
                      setState(() {
                        _statusFilter = val ? 'completed' : 'pending';
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            children: [
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
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search name or email',
                    border: InputBorder.none,
                    icon: Icon(Icons.search),
                  ),
                  style: TextStyle(fontSize: 12.sp),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filteredUsers.isEmpty
                    ? Center(
                        child: CustomText(
                          'No users found',
                          color: Colors.grey[700],
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredUsers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final purchases = userPurchases[user.id] ?? [];
                          final bool completed = _isCompleted(purchases);

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
                                backgroundColor: RButtoncolor.withOpacity(0.12),
                                child: const Icon(Icons.person,
                                    color: Colors.black87),
                              ),
                              title: CustomText(
                                user.fullName,
                                fontWeight: FontWeight.w700,
                                // maxLines: 1,
                                //  overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: CustomText(
                                user.email,
                                color: Colors.grey[700],
                                //maxLines: 1,
                                // overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: completed
                                      ? Colors.green.withOpacity(0.12)
                                      : ROrange.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: CustomText(
                                  completed ? 'CLEARED' : 'PENDING',
                                  fontWeight: FontWeight.w800,
                                  color: completed ? Colors.green : ROrange,
                                ),
                              ),
                              onTap: purchases.isEmpty
                                  ? () => ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content: Text('No purchases found.'),
                                      ))
                                  : () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) =>
                                            PurchaseDetailsModal(
                                          purchases: purchases,
                                          user: user,
                                        ),
                                      );
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
    });
  }
}
