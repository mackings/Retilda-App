import 'package:flutter/material.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:sizer/sizer.dart';

class LinearCompletionIndicator extends StatelessWidget {
  final int totalAmountToPay; // Total amount the user should pay
  final int totalAmountPaid; // Total amount the user has paid

  const LinearCompletionIndicator({
    Key? key,
    required this.totalAmountToPay,
    required this.totalAmountPaid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double completionRate = totalAmountToPay != 0 ? totalAmountPaid / totalAmountToPay : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText('Completion Rate: ${(completionRate * 100).toStringAsFixed(1)}%',fontWeight: FontWeight.w500,),

        SizedBox(height: 1.h), 
        LinearProgressIndicator(
          value: completionRate,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          borderRadius: BorderRadius.circular(8),
          minHeight: 3.h, // Responsive height of the progress bar
        ),
      //  SizedBox(height: 1.h), // Responsive vertical spacing
        // Text(
        //   'Paid: N$totalAmountPaid',
        //   style: TextStyle(fontSize: 12.sp),
        // ),
        // Text(
        //   'Total to Pay: N$totalAmountToPay',
        //   style: TextStyle(fontSize: 12.sp),
        // ),
      ],
    );
  }
}
