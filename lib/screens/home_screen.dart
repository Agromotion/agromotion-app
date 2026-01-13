import 'package:flutter/material.dart';
import '../components/status_card.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgroMotion Control'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(Icons.circle, color: isOnline ? Colors.green : Colors.red, size: 12),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                const StatusCard(title: 'Bateria', value: '85%', icon: Icons.battery_charging_full, color: Colors.green),
                const StatusCard(title: 'Ração', value: '45kg', icon: Icons.inventory_2, color: Colors.brown),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => setState(() => isMoving = !isMoving),
              icon: Icon(isMoving ? Icons.stop : Icons.play_arrow),
              label: Text(isMoving ? 'PARAR ROBÔ' : 'INICIAR ALIMENTAÇÃO'),
              style: FilledButton.styleFrom(
                backgroundColor: isMoving ? Colors.red : Colors.green,
                minimumSize: const Size(double.infinity, 60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}