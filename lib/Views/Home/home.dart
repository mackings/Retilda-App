import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retilda/Views/Auth/Signin.dart';
import 'package:retilda/Views/Auth/Signup.dart';
import 'package:retilda/Views/Home/dashboard.dart';
import 'package:retilda/Views/Products/cartpage.dart';
import 'package:retilda/Views/Profile/profile.dart';
import 'package:retilda/Views/Wallet/Purchasehistory.dart';
import 'package:retilda/Views/Wallet/transactions.dart';
import 'package:retilda/Views/Widgets/bottomnavbar.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:retilda/model/cartmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';




class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late List<CartItem> cartItems;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _initializePages();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cartItemsJson = prefs.getStringList('cartItems');
    if (cartItemsJson != null) {
      setState(() {
        cartItems = cartItemsJson
            .map((item) => CartItem.fromJson(jsonDecode(item)))
            .toList();
      });
    }
  }

  void _initializePages() {
    
    _pages = [
      Dashboard(),
      CartPage(),
      PurchaseHistory(),
      Transactions(),
      Profile()
    ];
    
  }

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
            icon: Icon(Icons.account_balance),
            label: 'Transactions',
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
