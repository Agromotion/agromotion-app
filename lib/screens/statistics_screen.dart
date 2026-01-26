import 'dart:ui';
import 'package:agromotion/utils/responsive_layout.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../components/glass_container.dart';
import '../components/agro_appbar.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final customColors = theme.extension<AppColorsExtension>()!;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(gradient: customColors.backgroundGradient),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // AppBar Compacta e Consistente
              const AgroAppBar(title: 'Estatísticas'),

              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.horizontalPadding,
                  vertical: 24,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionTitle(context, 'Resumo Geral'),
                    const SizedBox(height: 12),

                    // Grid de métricas rápidas adaptável
                    _buildQuickStatsGrid(
                      context.gridCrossAxisCount,
                      colorScheme,
                    ),

                    const SizedBox(height: 32),
                    _buildSectionTitle(context, 'Nível de Bateria (24h)'),
                    const SizedBox(height: 12),
                    _buildChartPlaceholder(
                      context,
                      'Desgaste de Bateria (%)',
                      Icons.show_chart,
                    ),

                    const SizedBox(height: 32),
                    _buildSectionTitle(context, 'Ração Empurrada por Dia'),
                    const SizedBox(height: 12),
                    _buildChartPlaceholder(
                      context,
                      'Kg de Ração / Dia',
                      Icons.bar_chart,
                    ),

                    const SizedBox(height: 32),
                    _buildSectionTitle(context, 'Últimas Missões'),
                    const SizedBox(height: 12),
                    _buildMissionLog(
                      context,
                      'Hoje, 07:02',
                      'Concluída',
                      '120kg',
                      Icons.check_circle_outline,
                      Colors.green,
                    ),
                    _buildMissionLog(
                      context,
                      'Hoje, 12:45',
                      'Obstáculo detetado',
                      '45kg',
                      Icons.error_outline,
                      Colors.amber,
                    ),
                    _buildMissionLog(
                      context,
                      'Ontem, 18:00',
                      'Concluída',
                      '135kg',
                      Icons.check_circle_outline,
                      Colors.green,
                    ),

                    const SizedBox(height: 120), // Espaço para a NavBar
                  ]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.primary.withAlpha(80),
      ),
    );
  }

  Widget _buildQuickStatsGrid(int crossAxisCount, ColorScheme colorScheme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatItem(
          'Alimentado',
          '1.2 Ton',
          Icons.scale,
          Colors.orange,
          colorScheme,
        ),
        _buildStatItem(
          'Distância',
          '45.8 km',
          Icons.route,
          Colors.blue,
          colorScheme,
        ),
        _buildStatItem('Ciclos', '124', Icons.loop, Colors.purple, colorScheme),
        _buildStatItem(
          'Eficiência',
          '94%',
          Icons.bolt,
          Colors.green,
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String title,
    String val,
    IconData icon,
    Color color,
    ColorScheme colorScheme,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const Spacer(),
          Text(
            val,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurface.withAlpha(50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartPlaceholder(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Container(
        height: 160,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colorScheme.primary.withAlpha(40), size: 48),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurface.withAlpha(60),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              "(Integração fl_chart pendente)",
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurface.withAlpha(30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionLog(
    BuildContext context,
    String date,
    String status,
    String qty,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            date,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            status,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withAlpha(60),
            ),
          ),
          trailing: Text(
            qty,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
