import 'package:agromotion/components/glass_container.dart';
import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? subtitle;
  final Widget? trailing;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle,
        trailing: trailing,
      ),
    );
  }
}
