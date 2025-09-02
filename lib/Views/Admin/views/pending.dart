import 'package:flutter/material.dart';
import 'package:retilda/Views/Admin/Api/service.dart';
import 'package:retilda/Views/Admin/model/model.dart';
import 'package:retilda/Views/Admin/widgets/purchasemodal.dart';



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
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Payments')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final filteredUsers = widget.users.where((user) {
      final completed = _isCompleted(userPurchases[user.id]!);
      return showCompleted ? completed : !completed;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Payments'),
        actions: [
          Row(
            children: [
              Text(showCompleted ? 'Completed' : 'Pending'),
              Switch(
                value: showCompleted,
                onChanged: (val) {
                  setState(() {
                    showCompleted = val;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) {
          final user = filteredUsers[index];
          final purchases = userPurchases[user.id]!;

          return ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text(user.fullName),
            subtitle: Text(user.email),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => PurchaseDetailsModal(
                  purchases: purchases,
                  user: user,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
