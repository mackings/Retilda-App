import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Auth/kyc.dart';
import 'package:retilda/Views/Merchant/upload.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/profiletile.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

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

  Future<void> _loadUserData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userDataString = sharedPreferences.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> userData = jsonDecode(userDataString);
      String token = userData['data']['token'];
      String username = userData['data']['user']['fullname'];
      String accttype = userData['data']['user']['accountType'];
      int credit = userData['data']['user']['creditScore'];
      setState(() {
        Token = token;
        Username = username;
        Credit = credit;
        Acctype = accttype;
      });

      print("User >>> $userData");
      print("UserName >>> $Username");
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
            padding: const EdgeInsets.only(left: 20, right:20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                  border: Border.all(width: 0.5, color: Colors.grey)),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      '$Username',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    SizedBox(
                      height: 1.h,
                    ),
                    Row(
                      children: [
                        CustomText(
                          '${Acctype == "premium" ? "Premium" : "Standard"} account',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        SizedBox(
                          width: 1.w,
                        ),
                        Acctype == 'premium'
                            ? Icon(
                                Icons.check_circle,
                                color: ROrange,
                              )
                            : Icon(Icons.check),
                      ],
                    ),
                    SizedBox(
                      height: 1.h,
                    ),
                    Row(
                      children: [
                        CustomText(
                          'Credit Score:',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        CustomText(
                          ' ${Credit.toString()==null?"KYC Not Completed":Credit.toString()}',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: ROrange,
                        ),
                      ],
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
                ProfileListItem(
                  icon: Icons.credit_card,
                  title: 'Debit Cards',
                  onTap: () {
                    print('Account Info tapped');
                  },
                ),
                ProfileListItem(
                  icon: Icons.policy_rounded,
                  title: 'Terms and Policy',
                  onTap: () {
                    // Handle navigation or other actions
                    print('Account Info tapped');
                  },
                ),

               ProfileListItem(
                  icon: Icons.space_dashboard_outlined,
                  title: 'Merchant',
                  onTap: () {

                   Navigator.push(context,
                  MaterialPageRoute(builder: (context) => UploadProducts()));
                    
                    print('Account Info tapped');
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
