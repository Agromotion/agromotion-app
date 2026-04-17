import 'package:agromotion/widgets/glass_container.dart';
import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onPressed;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Define o trailing: se houver onPressed, usa a seta; caso contrário, usa o trailing passado
    final Widget? effectiveTrailing = onPressed != null
        ? const Icon(Icons.chevron_right)
        : trailing;

    Widget content = GlassContainer(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle,
        trailing: effectiveTrailing,
      ),
    );

    // Se houver onPressed, envolvemos o card com InkWell para o efeito de clique
    if (onPressed != null) {
      return InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: content,
      );
    }

    return content;
  }
}
