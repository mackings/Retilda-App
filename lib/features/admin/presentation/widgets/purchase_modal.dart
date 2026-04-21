import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Admin/model/model.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:sizer/sizer.dart';

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
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, -6),
            )
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: RButtoncolor.withOpacity(0.1),
                      child: const Icon(Icons.person, color: Colors.black87),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            user.fullName,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.sp,
                          ),
                          CustomText(
                            user.email,
                            color: Colors.grey[700],
                            // maxLines: 1,
                            //overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 6),
                Expanded(
                  child: purchases.isEmpty
                      ? Center(
                          child: CustomText(
                            'No purchases found',
                            color: Colors.grey[700],
                          ),
                        )
                      : ListView.builder(
                          controller: controller,
                          itemCount: purchases.length,
                          itemBuilder: (context, index) {
                            final purchase = purchases[index];
                            final int totalPaid = purchase.payments
                                .fold(0, (sum, p) => sum + p.amountPaid);
                            final int price = purchase.product.price;
                            final bool isComplete = totalPaid >= price;

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: CustomText(
                                          purchase.product.name,
                                          fontWeight: FontWeight.w800,
                                          // maxLines: 1,
                                          //overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isComplete
                                              ? Colors.green.withOpacity(0.12)
                                              : ROrange.withOpacity(0.14),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: CustomText(
                                          isComplete ? 'COMPLETED' : 'PENDING',
                                          fontWeight: FontWeight.w800,
                                          color: isComplete
                                              ? Colors.green
                                              : ROrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.local_shipping_outlined,
                                          size: 16,
                                          color: purchase.deliveryStatus ==
                                                  "pending"
                                              ? ROrange
                                              : Colors.green),
                                      const SizedBox(width: 6),
                                      CustomText(
                                        'Delivery: ${purchase.deliveryStatus}',
                                        color: Colors.grey[700],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color:
                                                RButtoncolor.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                              Icons.payments_outlined),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              CustomText(
                                                'Plan: ${purchase.paymentPlan}',
                                                fontWeight: FontWeight.w700,
                                              ),
                                              CustomText(
                                                'Price: ${formatAmount(price)} · Paid: ${formatAmount(totalPaid)}',
                                                color: Colors.grey[700],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (purchase.payments.isEmpty)
                                    CustomText(
                                      'No payments yet',
                                      color: Colors.grey[700],
                                    )
                                  else
                                    ...purchase.payments.map((p) {
                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.grey.shade200),
                                        ),
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
                                                      : ROrange,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                CustomText(
                                                  p.status.toUpperCase(),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            CustomText(
                                              'Paid: ${formatAmount(p.amountPaid)} · To pay: ${formatAmount(p.amountToPay)}',
                                              color: Colors.grey[700],
                                            ),
                                            CustomText(
                                              'Payment Date: ${formatDate(p.paymentDate)}',
                                              color: Colors.grey[700],
                                            ),
                                            CustomText(
                                              'Next Payment: ${formatDate(p.nextPaymentDate)}',
                                              color: Colors.grey[700],
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                ],
                              ),
                            );
                          },
                        ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
