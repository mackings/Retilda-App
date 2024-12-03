import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;

  const CustomText(
    this.text, {
    Key? key,
    this.fontSize,
    this.fontWeight,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      softWrap: true,
      style: GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}


class CustomTextFormField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final Function(String)? onChanged;
  final Function()? onEditingComplete;
  final Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final bool isPasswordField;

  CustomTextFormField({
    required this.hintText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.focusNode,
    this.onChanged,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.validator,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.isPasswordField = false,
  });

  @override
  Widget build(BuildContext context) {
    ValueNotifier<bool> obscureText = ValueNotifier<bool>(isPasswordField);

    return ValueListenableBuilder<bool>(
      valueListenable: obscureText,
      builder: (context, isObscured, child) {
        return Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPasswordField ? isObscured : false,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            focusNode: focusNode,
            onChanged: onChanged,
            onEditingComplete: onEditingComplete,
            onFieldSubmitted: onFieldSubmitted,
            validator: validator,
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              hintText: hintText,
              suffixIcon: isPasswordField
                  ? GestureDetector(
                      onTap: () {
                        obscureText.value = !isObscured;
                      },
                      child: Icon(
                        isObscured ? Icons.visibility_off : Icons.visibility,
                      ),
                    )
                  : (suffixIcon != null
                      ? GestureDetector(
                          onTap: onSuffixIconTap,
                          child: Icon(suffixIcon),
                        )
                      : null),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 13.0, horizontal: 20.0),
              border: InputBorder.none,
            ),
          ),
        );
      },
    );
  }
}




class CustomBtn extends StatelessWidget {
  final String text;
  final Function()? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final double width;
  final double height;

  const CustomBtn({
    required this.text,
    this.onPressed,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
    this.borderRadius = 8.0,
    this.width  = double.infinity,
    this.height = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final adjustedWidth = width - 16.0; 

    return Padding(
      padding: const EdgeInsets.only(left: 5,right: 5),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: TextButton(
          onPressed: onPressed,
          child: CustomText(
            text,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

