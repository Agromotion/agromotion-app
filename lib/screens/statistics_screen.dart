import 'package:agromotion/utils/responsive_layout.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../components/agro_appbar.dart';
import '../components/statistics/stat_item_card.dart';
import '../components/statistics/chart_placeholder.dart';
import '../components/statistics/mission_log_tile.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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

                    // Grid de métricas
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: context.gridCrossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: const [
                        StatItemCard(
                          title: 'Alimentado',
                          value: '1.2 Ton',
                          icon: Icons.scale,
                          iconColor: Colors.orange,
                        ),
                        StatItemCard(
                          title: 'Distância',
                          value: '45.8 km',
                          icon: Icons.route,
                          iconColor: Colors.blue,
                        ),
                        StatItemCard(
                          title: 'Ciclos',
                          value: '124',
                          icon: Icons.loop,
                          iconColor: Colors.purple,
                        ),
                        StatItemCard(
                          title: 'Eficiência',
                          value: '94%',
                          icon: Icons.bolt,
                          iconColor: Colors.green,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    _buildSectionTitle(context, 'Nível de Bateria (24h)'),
                    const SizedBox(height: 12),
                    const ChartPlaceholder(
                      label: 'Desgaste de Bateria (%)',
                      icon: Icons.show_chart,
                    ),

                    const SizedBox(height: 32),
                    _buildSectionTitle(context, 'Ração Empurrada por Dia'),
                    const SizedBox(height: 12),
                    const ChartPlaceholder(
                      label: 'Kg de Ração / Dia',
                      icon: Icons.bar_chart,
                    ),

                    const SizedBox(height: 32),
                    _buildSectionTitle(context, 'Últimas Missões'),
                    const SizedBox(height: 12),
                    const MissionLogTile(
                      date: 'Hoje, 07:02',
                      status: 'Concluída',
                      qty: '120kg',
                      icon: Icons.check_circle_outline,
                      statusColor: Colors.green,
                    ),
                    const MissionLogTile(
                      date: 'Hoje, 12:45',
                      status: 'Obstáculo detetado',
                      qty: '45kg',
                      icon: Icons.error_outline,
                      statusColor: Colors.amber,
                    ),
                    const MissionLogTile(
                      date: 'Ontem, 18:00',
                      status: 'Concluída',
                      qty: '135kg',
                      icon: Icons.check_circle_outline,
                      statusColor: Colors.green,
                    ),

                    const SizedBox(height: 120),
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
}
