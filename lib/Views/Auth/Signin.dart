import 'package:flutter/material.dart';
import 'package:retilda/Views/Auth/Signup.dart';
import 'package:retilda/Views/Home/home.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:sizer/sizer.dart';

class Signin extends StatefulWidget {
  const Signin({super.key});

  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Center(
          child: Column(
            children: [

              SizedBox(height: 7.h,),
        
        CustomText(
          'Retilda',
          fontSize: 25.sp,
          fontWeight: FontWeight.bold,
          color: ROrange,
        ),

        SizedBox(height: 4.h,),

        CustomText(
          'Sign in',
          fontSize: 15.sp,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        
        SizedBox(height: 4.h,),

        CustomTextFormField(
          hintText: 'Email',
          suffixIcon: Icons.email,
          onChanged: (value) {
   
                    },
      ),


        SizedBox(height: 4.h,),

        CustomTextFormField(
          hintText: 'Password',
          suffixIcon: Icons.visibility_off,
          onChanged: (value) {
   
                    },

      ),




Padding(
  padding: EdgeInsets.only(left: 0.59 * MediaQuery.of(context).size.width, top: 0.02 * MediaQuery.of(context).size.height),
  child: SizedBox(
    width: MediaQuery.of(context).size.width,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Signin()),
            );
          },
          child: CustomText(
            'Forgot password',
            color: ROrange,
          ),
        ),
      ],
    ),
  ),
),

SizedBox(height: 5.h,),

CustomBtn(
  text: 'Sign in',
  onPressed: () {

              Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
  },
  backgroundColor: RButtoncolor,
  borderRadius: 20.0,
),

Padding(
  padding: EdgeInsets.only(right: 0.55 * MediaQuery.of(context).size.width, top: 0.02 * MediaQuery.of(context).size.height),
  child: SizedBox(
    width: MediaQuery.of(context).size.width,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          'New user? ',
          color: Colors.black,  
        ),

        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Signup()),
            );
          },
          child: CustomText(
            'Sign up',
            color: ROrange,
          ),
        ),
      ],
    ),
  ),
),


       
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}
