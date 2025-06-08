import 'package:flutter/material.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:sizer/sizer.dart';

class PaymentBreakdownWidget extends StatelessWidget {
  final String title;
  final String amount;
  final int? index;

  const PaymentBreakdownWidget({
    Key? key,
    required this.title,
    required this.amount,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        children: [
          Container(
            height: 8.h,
            decoration: BoxDecoration(
               color: Colors.white, 
               borderRadius: BorderRadius.circular(8),
               border: Border.all(width: 0.5,color: Colors.black)
            ),
            child: Padding(
              padding: EdgeInsets.all(2.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    title,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  CustomText(
                    amount,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: ROrange,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
