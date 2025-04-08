import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retilda/Views/Products/Connect/views/connect.dart';
import 'package:retilda/Views/Products/details.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/products.dart';
import 'package:sizer/sizer.dart';

class PaymentOptions extends StatelessWidget {
  final Product product;
  final bool loading;
  final bool? activated;
  final VoidCallback purchaseProduct;
  final VoidCallback initializePayment;

  const PaymentOptions({
    super.key,
    required this.product,
    required this.loading,
    required this.activated,
    required this.purchaseProduct,
    required this.initializePayment,
  });

  void _showConnectDialog(BuildContext context) {
    bool termsAccepted = false;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'Connect',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'To proceed, please consent to connect your bank account to the platform and read our privacy policy for more details.',
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: termsAccepted,
                      onChanged: (value) {
                        setState(() => termsAccepted = value!);
                      },
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'I accept the ',
                          children: [
                            WidgetSpan(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => InAppWebViewPage(
                                        url:
                                            'https://docs.google.com/document/d/1zWEYmMZ_tRhC198qMsN5rP55YmeQ8rtiuTbaPEC_Fw0/edit?usp=sharing',
                                        title: 'Terms and Policy',
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Terms',
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: termsAccepted
                    ? () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ConnectAccount(),
                          ),
                        );
                      }
                    : null,
                child: const Text('Connect'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,##0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 15.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                "N${currency.format(product.price)}",
                fontWeight: FontWeight.w700,
                fontSize: 12.sp,
              ),
              loading
                  ? const CustomText("Making payments...")
                  : GestureDetector(
                      onTap: () {
                        if (activated!) {
                          _showConnectDialog(context);
                        } else {
                          purchaseProduct();
                        }
                      },
                      child: Container(
                        height: 6.h,
                        width: 50.w,
                        decoration: BoxDecoration(
                          color: RButtoncolor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: CustomText(
                            "Pay Installments",
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        const Center(child: Text("OR")),
        SizedBox(height: 2.h),
        GestureDetector(
          onTap: () => initializePayment(),
          child: Container(
            height: 6.h,
            width: MediaQuery.of(context).size.width - 10.w,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                "One Time Payment",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
