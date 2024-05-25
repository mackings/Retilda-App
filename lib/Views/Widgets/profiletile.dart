import 'package:flutter/material.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/widgets.dart';

class ProfileListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const ProfileListItem({
    Key? key,
    required this.icon,
    required this.title,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: RButtoncolor 
      ),
      title: CustomText(
        title,
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey,
        size: 16.0,
      ),
      onTap: onTap,
    );
  }
}
