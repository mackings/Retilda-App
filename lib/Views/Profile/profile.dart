import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Auth/kyc.dart';
import 'package:retilda/Views/Merchant/upload.dart';
import 'package:retilda/Views/Products/Update/ProducUpdate.dart';
import 'package:retilda/Views/Products/terms.dart';
import 'package:retilda/Views/Profile/support.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/profiletile.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;


class Profile extends ConsumerStatefulWidget {
  const Profile({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<Profile> {
  String? Token;
  String? Username;
  String? Acctype;
  int? Credit;
  String? role;
  String? refferalCode;
  int? refferalBonus;

  Future<void> _loadUserData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userDataString = sharedPreferences.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      String token = userData['data']['token'];
      String username = userData['data']['user']['fullName'];
      String accttype = userData['data']['user']['accountType'];
      int credit = userData['data']['user']['creditScore'];
      String myrole = userData['data']['user']['roles'];
      String mycode = userData['data']['user']['referralCode'];
      int mybonus = userData['data']['user']['referralBonus'];

      setState(() {
        Token = token;
        Username = username;
        Credit = credit;
        Acctype = accttype;
        role = myrole;
        refferalCode = mycode;
        refferalBonus = mybonus;
      });

      print("User >>> $userData");
      print("UserName >>> $Username");
      print("User Role $role");
      print("User Code  $refferalCode");
      print("User Code  $refferalBonus");

    }
  }

  @override
  void initState() {
    _loadUserData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: CustomText(
          'Profile',
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [


Padding(
  padding: EdgeInsets.symmetric(horizontal: 5.w), // Responsive padding
  child: Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(width: 0.5, color: Colors.grey),
    ),
    child: ListTile(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Username Display
          CustomText(
            Username ?? "User", // Fallback for null Username
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
          SizedBox(height: 1.h),

          // Account Type Row

          Row(
            children: [
              CustomText(
                '${(Acctype ?? "Standard") == "premium" ? "Premium" : "Standard"} Account',
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
              SizedBox(width: 1.w),
              Icon(
                Icons.check_circle,
                color: (Acctype == "premium") ? ROrange : Colors.grey,
              ),
            ],
          ),


          SizedBox(height: 1.h),

          // Referral Code Display and Copy
          
          GestureDetector(
            onTap: () {
              if (refferalCode != null) {
                Clipboard.setData(ClipboardData(text: refferalCode!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Referral Code Copied!")),
                );
              }
            },
            child: Row(
              children: [
                CustomText('Referral Code: ${refferalCode ?? "N/A"}'),
                SizedBox(width: 5.w),
                Icon(Icons.copy),
              ],
            ),
          ),


          SizedBox(height: 2.h),

          // Redeem Button with Referral Bonus
        if (role != 'user')

          GestureDetector(  
            onTap: () async {
              if (refferalBonus != null && refferalBonus! > 0) {
                try {
                  final response = await http.put(
                    Uri.parse('https://retilda-fintech.vercel.app/Api/moveReferralBonus'),
                    headers: {
                      'Content-Type': 'application/json',
                      'Authorization': 'Bearer ${Token ?? ""}', // Null-safe token
                    },
                    body: json.encode({"referralBonus": refferalBonus.toString()}),
                  );
  
                  if (response.statusCode == 200) {
                    final responseData = json.decode(response.body);
                    if (responseData['success'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Referral bonus redeemed successfully!")),
                      );
                      setState(() {
                        refferalBonus = 0; // Reset referral bonus
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(responseData['message'] ?? "Failed to redeem.")),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to redeem. Please try again.")),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("An error occurred: $e")),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("No referral bonus to redeem.")),
                );
              }
            },
            
            child: Row(
              
              children: [

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText('Referral Bonus: ${refferalBonus ?? "0"}'),
                     SizedBox(width: 5.w),
                Container(
                  height: 5.h,
                  width: 30.w,
                  decoration: BoxDecoration(
                    color: ROrange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: CustomText(
                      "Redeem",
                      color: Colors.white,
                    ),
                  ),
                ),
                  ],
                ),

              ],
            ),
          ),
        ],
      ),
    ),
  ),
),




          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 50),
            child: Column(
              children: [
                ProfileListItem(
                  icon: Icons.check_circle,
                  title: 'KYC',
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => KYC()));
                  },
                ),
                // ProfileListItem(
                //   icon: Icons.credit_card,
                //   title: 'Debit Cards',
                //   onTap: () {
                //     print('Account Info tapped');
                //   },
                // ),
                ProfileListItem(
                  icon: Icons.policy_rounded,
                  title: 'Terms and Policy',
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TermsAndPolicyPage()));
                  },
                ),

                ProfileListItem(
                  icon: Icons.support_agent,
                  title: 'Support',
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => Support()));
                  },
                ),

                if (role != 'user')
                  ProfileListItem(
                    icon: Icons.space_dashboard_outlined,
                    title: 'Merchant',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => UploadProducts()),
                      );
                      print('Merchant tapped');
                    },
                  ),

                if (role != 'user')
                  ProfileListItem(
                    icon: Icons.system_update_alt,
                    title: 'Update Product',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Producupdate()),
                      );
                      print('Merchant tapped');
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
