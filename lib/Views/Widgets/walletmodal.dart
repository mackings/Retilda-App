import 'package:flutter/material.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:sizer/sizer.dart';

class WalletPaymentModalSheet extends StatefulWidget {
  final String walletBalance;
  final List<String> paymentOptions;
  final void Function(String?)? onPaymentOptionSelected;
  final bool isButtonEnabled;
  final Widget Function() buttonWidgetBuilder;

  const WalletPaymentModalSheet({
    Key? key,
    required this.walletBalance,
    required this.paymentOptions,
    required this.onPaymentOptionSelected,
    required this.isButtonEnabled,
    required this.buttonWidgetBuilder,
  }) : super(key: key);

  @override
  State<WalletPaymentModalSheet> createState() =>
      _WalletPaymentModalSheetState();
}

class _WalletPaymentModalSheetState extends State<WalletPaymentModalSheet> {
  String selectedPaymentOption = "";

  @override
  void initState() {
    super.initState();
    selectedPaymentOption = widget.paymentOptions.first;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: 60.h,
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Align(
                  alignment: Alignment.topRight,
                  child: Icon(
                    Icons.close,
                    color: Colors.black,
                  )),
            ),

            // SizedBox(
            //   height: 2.h,
            // ),

            CustomText(' ${widget.walletBalance}'),
            SizedBox(height: 2.h),
            CustomText("Select payment option",
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,),

            SizedBox(height: 3.h),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(width: 0.5, color: Colors.black),
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedPaymentOption,
                onChanged: (newValue) {
                  setState(() {
                    selectedPaymentOption = newValue!;
                  });
                  widget.onPaymentOptionSelected!(newValue);
                },
                underline: SizedBox(),
                
                items: widget.paymentOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: CustomText(option),
                  );
                }).toList(),
                selectedItemBuilder: (BuildContext context) {
                  return widget.paymentOptions.map<Widget>((String value) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            CustomText(value),
                          ],
                        ),
                      ),
                    );
                  }).toList();
                },
              ),
            ),

            SizedBox(height: 3.h),
            widget.buttonWidgetBuilder(),
          ],
        ),
      ),
    );
  }
}
