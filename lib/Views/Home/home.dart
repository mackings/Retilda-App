import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Auth/Signin.dart';
import 'package:retilda/Views/Auth/Signup.dart';
import 'package:retilda/Views/Home/dashboard.dart';
import 'package:retilda/Views/Widgets/bottomnavbar.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:sizer/sizer.dart';


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int _selectedIndex = 0;

  static List<Widget> _pages = <Widget>[
    Dashboard(),
    Signup(),
    Signin(),
    Signup(),
    Dashboard(),


  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: _pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[

          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            label: 'Favourites',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),

        ],

        currentIndex: _selectedIndex,
        selectedItemColor: ROrange,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        elevation: 0,

      ),
    );
  }
}
