
import 'package:flutter/material.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/widgets.dart';

class PaymentButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  final String buttonText;

  const PaymentButton({
    Key? key,
    required this.onPressed,
    required this.buttonText,
  }) : super(key: key);

  @override
  State<PaymentButton> createState() => _PaymentButtonState();
}

class _PaymentButtonState extends State<PaymentButton> {
  bool _isPaymentLoading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        setState(() {
          _isPaymentLoading = true;
        });
        await widget.onPressed();
        setState(() {
          _isPaymentLoading = false;
        });
      },
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
        decoration: BoxDecoration(
          color: _isPaymentLoading ? Colors.grey : ROrange,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: CustomText(
          _isPaymentLoading ? "Making Payments": widget.buttonText,
          color: Colors.white,
        )
      ),
    );
  }
}