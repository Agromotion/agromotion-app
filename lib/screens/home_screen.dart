import 'dart:ui';

import 'package:agromotion/components/glass_container.dart';
import 'package:agromotion/components/status_card.dart';
import 'package:flutter/material.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isOnline = true;
  bool isMoving = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: theme.brightness == Brightness.dark
                  ? [const Color(0xFF112211), const Color(0xFF000000)]
                  : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
            ),
          ),
        ),

        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Agromotion Control'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.circle,
                  color: isOnline ? Colors.green : Colors.red,
                  size: 12,
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    GlassContainer(
                      child: StatusCard(
                        title: 'Bateria',
                        value: '85%',
                        icon: Icons.battery_charging_full,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    GlassContainer(
                      child: StatusCard(
                        title: 'Ração',
                        value: '45kg',
                        icon: Icons.inventory_2,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: FilledButton.icon(
                      onPressed: () => setState(() => isMoving = !isMoving),
                      icon: Icon(isMoving ? Icons.stop : Icons.play_arrow),
                      label: Text(
                        isMoving ? 'PARAR ROBÔ' : 'INICIAR ALIMENTAÇÃO',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: isMoving
                            ? Colors.red.withAlpha(180)
                            : Colors.green.withAlpha(180),
                        minimumSize: const Size(double.infinity, 65),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.white.withAlpha(40)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
