import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retilda/Views/Home/dashboard.dart';
import 'package:retilda/Views/Products/cartpage.dart';
import 'package:retilda/Views/Profile/profile.dart';
import 'package:retilda/Views/Wallet/Purchasehistory.dart';
import 'package:retilda/Views/Wallet/transactions.dart';
import 'package:retilda/core/theme/app_theme.dart';
import 'package:retilda/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:retilda/model/cartmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late List<CartItem> cartItems;

  late final List<Widget> _pages;
  late final List<_NavItemConfig> _navItems;

  @override
  void initState() {
    super.initState();
    _initializePages();
    _initializeNavItems();
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
    _pages = const [
      Dashboard(),
      CartPage(),
      PurchaseHistory(),
      Transactions(),
      Profile()
    ];
  }

  void _initializeNavItems() {
    _navItems = const [
      _NavItemConfig(
        label: 'Home',
        activeIcon: Icons.home_rounded,
        inactiveIcon: Icons.home_outlined,
      ),
      _NavItemConfig(
        label: 'Cart',
        activeIcon: Icons.shopping_bag_rounded,
        inactiveIcon: Icons.shopping_bag_outlined,
      ),
      _NavItemConfig(
        label: 'History',
        activeIcon: Icons.receipt_long_rounded,
        inactiveIcon: Icons.receipt_long_outlined,
      ),
      _NavItemConfig(
        label: 'Wallet',
        activeIcon: Icons.account_balance_wallet_rounded,
        inactiveIcon: Icons.account_balance_wallet_outlined,
      ),
      _NavItemConfig(
        label: 'Account',
        activeIcon: Icons.person_rounded,
        inactiveIcon: Icons.person_outline_rounded,
      ),
    ];
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      ProviderScope.containerOf(
        context,
        listen: false,
      ).invalidate(walletOverviewProvider);
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNavItem({required _NavItemConfig item, required int index}) {
    final bool isSelected = _selectedIndex == index;
    const Color activeColor = AppTheme.ink;
    const Color accentColor = AppTheme.accent;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(0xFFF6FAFD),
                    Color(0xFFEAF3FB),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? activeColor.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                isSelected ? item.activeIcon : item.inactiveIcon,
                color: isSelected ? Colors.white : Colors.grey[700],
                size: 15,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : Colors.grey[700],
                fontSize: isSelected ? 11.8 : 11.2,
              ),
            ),
            const SizedBox(height: 1),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 1,
              width: isSelected ? 18 : 4,
              decoration: BoxDecoration(
                color: isSelected ? accentColor : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
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
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppTheme.ink.withValues(alpha: 0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Row(
              children: List.generate(
                _navItems.length,
                (index) => Expanded(
                  child: _buildNavItem(item: _navItems[index], index: index),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemConfig {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const _NavItemConfig({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });
}
