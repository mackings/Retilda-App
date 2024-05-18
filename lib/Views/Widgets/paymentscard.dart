import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:sizer/sizer.dart';

class PaymentSummaryCard extends StatelessWidget {
  
  final String imageUrl;
  final String title;
  final String subtitle;
  final DateTime date;

  const PaymentSummaryCard({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.date, 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String formatDate(DateTime date) {
      final DateFormat formatter = DateFormat('E MMM d y');
      return formatter.format(date);
    }

    String formattedDate = formatDate(date); // Use the provided date

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: EdgeInsets.all(16.0),
        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(width: 0.5, color: Colors.grey),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: CustomText(formattedDate,fontWeight: FontWeight.w600,),
            ),
            SizedBox(height: 8.0),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage: NetworkImage(imageUrl),
                radius: 30.0,
              ),
              title: CustomText(
                title,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
              subtitle: CustomText(subtitle,color: ROrange,),
            ),
          ],
        ),
      ),
    );
  }
}
