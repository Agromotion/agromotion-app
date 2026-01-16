import 'package:flutter/material.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise AgroMotion'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Resumo Geral'),
            const SizedBox(height: 12),
            // Grid de métricas rápidas
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _buildQuickStat(
                  context,
                  'Alimentado',
                  '1.2 Ton',
                  Icons.scale,
                  Colors.orange,
                ),
                _buildQuickStat(
                  context,
                  'Distância',
                  '45.8 km',
                  Icons.route,
                  Colors.blue,
                ),
                _buildQuickStat(
                  context,
                  'Ciclos',
                  '124',
                  Icons.loop,
                  Colors.purple,
                ),
                _buildQuickStat(
                  context,
                  'Eficiência',
                  '94%',
                  Icons.bolt,
                  Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Nível de Bateria (24h)'),
            _buildChartPlaceholder(
              context,
              'Gráfico de Linha: Desgaste de Bateria (%)',
            ),

            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Ração Empurrada por Dia'),
            _buildChartPlaceholder(context, 'Gráfico de Barras: Kg/Dia'),

            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Últimas Missões'),
            const SizedBox(height: 12),
            // Placeholder de histórico
            _buildMissionLog(
              context,
              'Hoje, 07:02',
              'Concluída',
              '120kg',
              Icons.check_circle,
              Colors.green,
            ),
            _buildMissionLog(
              context,
              'Hoje, 12:45',
              'Obstáculo detetado',
              '45kg',
              Icons.warning,
              Colors.amber,
            ),
            _buildMissionLog(
              context,
              'Ontem, 18:00',
              'Concluída',
              '135kg',
              Icons.check_circle,
              Colors.green,
            ),

            const SizedBox(height: 40), // Espaço final para não bater no fundo
          ],
        ),
      ),
    );
  }

  // Widget para os títulos das secções
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  // Widget para métricas em grelha (mais "sexy" que listas simples)
  Widget _buildQuickStat(
    BuildContext context,
    String title,
    String val,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const Spacer(),
            Text(
              val,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  // Placeholder para os gráficos (futuro: usar o package fl_chart)
  Widget _buildChartPlaceholder(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainer.withAlpha(50),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart,
                color: colorScheme.outlineVariant,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: colorScheme.outline)),
            ],
          ),
        ),
      ),
    );
  }

  // Item do log de missões
  Widget _buildMissionLog(
    BuildContext context,
    String date,
    String status,
    String qty,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          date,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(status),
        trailing: Text(
          qty,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
