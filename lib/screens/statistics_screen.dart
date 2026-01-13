import 'package:flutter/material.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estatísticas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatItem(context, 'Total Alimentado', '1.2 Ton', Icons.scale, Colors.orange),
            _buildStatItem(context, 'Distância Total', '45.8 km', Icons.route, Colors.blue),
            _buildStatItem(context, 'Eficiência Média', '94%', Icons.auto_graph, Colors.green),
            const SizedBox(height: 20),
            const Card(
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: Center(child: Text('Gráfico de Consumo (Em breve)')),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String title, String val, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }
}