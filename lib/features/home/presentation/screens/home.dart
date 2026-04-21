import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:retilda/Views/Home/dashboard.dart';
import 'package:retilda/Views/Products/cartpage.dart';
import 'package:retilda/Views/Profile/profile.dart';
import 'package:retilda/Views/Wallet/Purchasehistory.dart';
import 'package:retilda/Views/Wallet/transactions.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/model/cartmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Widget _buildNavItem(
      {required IconData icon, required String label, required int index}) {
    final bool isSelected = _selectedIndex == index;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 14 : 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? ROrange.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? ROrange : Colors.grey[600],
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  fontSize: 13,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(icon: Icons.home, label: 'Home', index: 0),
                _buildNavItem(
                    icon: Icons.shopping_cart, label: 'Cart', index: 1),
                _buildNavItem(icon: Icons.history, label: 'History', index: 2),
                _buildNavItem(
                    icon: Icons.account_balance,
                    label: 'Transactions',
                    index: 3),
                _buildNavItem(icon: Icons.person, label: 'Account', index: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
