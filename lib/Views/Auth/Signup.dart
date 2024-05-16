import 'package:flutter/material.dart';
import 'package:retilda/Views/Auth/Signin.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:sizer/sizer.dart';

class Signup extends StatefulWidget {
  const Signup({Key? key}) : super(key: key);

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          body: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                    CustomText(
                      'Retilda',
                      fontSize: 25.sp,
                      fontWeight: FontWeight.bold,
                      color: ROrange,
                    ),
                    SizedBox(height: 4.h),
                    CustomText(
                      'Sign up',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    SizedBox(height: 4.h),
                    CustomTextFormField(
                      hintText: 'Full Name',
                      onChanged: (value) {},
                    ),
                    SizedBox(height: 4.h),
                    CustomTextFormField(
                      hintText: 'Email',
                      suffixIcon: Icons.email,
                      onChanged: (value) {},
                    ),
                    SizedBox(height: 4.h),
                    CustomTextFormField(
                      hintText: 'Phone Number',
                      suffixIcon: Icons.phone,
                      onChanged: (value) {},
                    ),
                    SizedBox(height: 4.h),
                    CustomTextFormField(
                      hintText: 'Password',
                      suffixIcon: Icons.visibility_off,
                      onChanged: (value) {},
                    ),
                    SizedBox(height: 4.h),

                    SizedBox(height: 4.h),
                    CustomBtn(
                      text: 'Sign up',
                      onPressed: () {
                        // Signup action
                      },
                      backgroundColor: RButtoncolor,
                      borderRadius: 20.0,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          'Already have an account? ',
                          color: Colors.black,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => Signin()),
                            );
                          },
                          child: CustomText(
                            'Sign in',
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
