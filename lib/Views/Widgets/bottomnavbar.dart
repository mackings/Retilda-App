
import 'package:flutter/material.dart';


class CustomBottomNavBar extends StatelessWidget {
  final ValueChanged<int> onTabSelected;
  final Color color;
  final Color selectedColor;
  final List<CustomBottomAppBarItem> items;
  final int selectedIndex;

  const CustomBottomNavBar({
    required this.onTabSelected,
    required this.color,
    required this.selectedColor,
    required this.items,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTabSelected,
      backgroundColor: color,
      selectedItemColor: selectedColor,
      unselectedItemColor: Colors.grey,
      items: items.map((item) => item.build(context)).toList(),
    );
  }
}

class CustomBottomAppBarItem {
  final IconData iconData;
  final String label;

  CustomBottomAppBarItem(this.iconData, this.label);

  BottomNavigationBarItem build(BuildContext context) {
    return BottomNavigationBarItem(
      icon: Icon(iconData),
      label: label,
    );
  }
}