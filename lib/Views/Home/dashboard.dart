import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Auth/Signin.dart';
import 'package:retilda/Views/Auth/Signup.dart';
import 'package:retilda/Views/Widgets/bottomnavbar.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/indicators.dart';
import 'package:retilda/Views/Widgets/searchwidget.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:sizer/sizer.dart';

class Dashboard extends ConsumerStatefulWidget {
  const Dashboard({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<Dashboard> {

  TextEditingController searchcontroller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          body: Container(
            child: Column(
              children: [
                SizedBox(height: 8.h,),
                SearchContainer(controller: searchcontroller, onFilterPressed: () {}),
                Expanded(child: CarouselPageView()),

                
              ],
            ),
          ),
        );
      },
    );
  }
}
