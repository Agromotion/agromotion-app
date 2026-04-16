import 'package:flutter/material.dart';

class AgroBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const AgroBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      onPressed: onTap ?? () => Navigator.pop(context),
      color: Theme.of(context).colorScheme.onSurface,
      iconSize: 20,
      splashRadius: 24,
    );
  }
}
