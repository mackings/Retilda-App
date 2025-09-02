import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Admin/model/model.dart';




class PurchaseDetailsModal extends StatelessWidget {
  final List<GlancePurchase> purchases;
  final GlanceUser user; // ✅ store user here

  const PurchaseDetailsModal({
    super.key,
    required this.purchases,
    required this.user, // ✅ fix: properly assign user
  });

  String formatDate(String? date) {
    if (date == null) return 'Not available';
    try {
      return DateFormat('d MMM, yyyy • h:mm a').format(DateTime.parse(date));
    } catch (e) {
      return date;
    }
  }

  String formatAmount(num amount) {
    final formatter = NumberFormat('#,##0', 'en_NG');
    return '₦${formatter.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${user.fullName} ', // ✅ show user's name in header
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(color: Colors.grey[400]),

            // Purchases list
            Expanded(
              child: purchases.isEmpty
                  ? Center(
                      child: Text(
                        'No purchases found',
                        style: GoogleFonts.poppins(fontSize: 15),
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      itemCount: purchases.length,
                      itemBuilder: (context, index) {
                        final purchase = purchases[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product name & delivery status
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    purchase.product.name,
                                    style: GoogleFonts.poppins(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Icon(
                                    purchase.deliveryStatus == "pending"
                                        ? Icons.pending
                                        : Icons.check_circle,
                                    color: purchase.deliveryStatus == "pending"
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Divider(color: Colors.grey[300]),
                              const SizedBox(height: 8),

                              // Payment Plan
                              Row(
                                children: [
                                  const Icon(Icons.schedule,
                                      color: Colors.blue, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Payment Plan: ${purchase.paymentPlan}',
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Payments
                              if (purchase.payments.isEmpty)
                                Text(
                                  'No payments yet',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14, color: Colors.grey[600]),
                                )
                              else
                                ...purchase.payments.map((p) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              p.status == "completed"
                                                  ? Icons.check_circle
                                                  : Icons.pending,
                                              color: p.status == "completed"
                                                  ? Colors.green
                                                  : Colors.orange,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              p.status.toUpperCase(),
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.attach_money,
                                                size: 18, color: Colors.green),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Paid: ${formatAmount(p.amountPaid)}',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 14),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.money_off,
                                                size: 18, color: Colors.red),
                                            const SizedBox(width: 6),
                                            Text(
                                              'To Pay: ${formatAmount(p.amountToPay)}',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 14),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.payment,
                                                size: 18, color: Colors.blue),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Payment Date: ${formatDate(p.paymentDate)}',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 14),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.next_plan,
                                                size: 18, color: Colors.orange),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Next Payment: ${formatDate(p.nextPaymentDate)}',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 14),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Divider(color: Colors.grey[300]),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
