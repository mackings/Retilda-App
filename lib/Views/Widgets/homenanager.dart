
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class HomeManager extends ConsumerStatefulWidget {
//   const HomeManager({Key? key}) : super(key: key);

//   @override
//   ConsumerState<ConsumerStatefulWidget> createState() => _HomeManagerState();
// }

// class _HomeManagerState extends ConsumerState<HomeManager> {
//   int selectedIndex = 0;

//   @override
//   void initState() {
//     super.initState();

//   }

//   void _updateIndex() {
//     setState(() {
//       selectedIndex = 3;
//     });
//   }

//   void _selectedTab(int index) {
//     setState(() {
//       selectedIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         return false;
//       },
//       child: Scaffold(
//         body: SizedBox(
//           child: tabOptions.elementAt(selectedIndex),
//         ),
//         bottomNavigationBar: CustomBottomNavBar(
//           onTabSelected: _selectedTab,
//           color: ZeehColors.greyColor,
//           selectedColor: ZeehColors.buttonPurple,
//           items: [
//             CustomBottomAppBarItem(
//               ZeehAssets.homeIcon,
//               'Home',
//             ),
//             CustomBottomAppBarItem(
//               ZeehAssets.credithomeicon,
//               'Credit Insight',
//             ),
//             CustomBottomAppBarItem(
//               ZeehAssets.transicon,
//               'Transactions',
//             ),
//             CustomBottomAppBarItem(
//               ZeehAssets.settingsIcon,
//               'Settings',
//             ),
//           ],
//           selectedIndex: selectedIndex,
//         ),
//       ),
//     );
//   }
// }