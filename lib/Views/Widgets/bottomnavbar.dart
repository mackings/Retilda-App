
import 'package:flutter/material.dart';
import 'package:retilda/Views/Widgets/components.dart';

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
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.92), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        currentIndex: selectedIndex,
        onTap: onTabSelected,
        selectedItemColor: selectedColor,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        items: items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final bool isActive = idx == selectedIndex;
          return BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActive ? Colors.white.withOpacity(0.18) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: isActive
                    ? Border.all(color: selectedColor.withOpacity(0.4))
                    : null,
              ),
              child: Icon(
                item.iconData,
                color: isActive ? selectedColor : Colors.white,
              ),
            ),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

class CustomBottomAppBarItem {
  final IconData iconData;
  final String label;

  CustomBottomAppBarItem(this.iconData, this.label);
}
