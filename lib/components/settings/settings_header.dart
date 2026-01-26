import 'package:agromotion/utils/responsive_layout.dart';
import 'package:flutter/material.dart';

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        context.horizontalPadding - 12,
        20,
        context.horizontalPadding,
        10,
      ),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
              color: theme.colorScheme.onSurface,
              iconSize: 20,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Definições",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Configure a sua plataforma Agromotion",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withAlpha(50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
