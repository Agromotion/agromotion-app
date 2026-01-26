import 'package:agromotion/components/agro_appbar.dart';
import 'package:agromotion/utils/responsive_layout.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../components/glass_container.dart';

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
    final customColors = theme.extension<AppColorsExtension>()!;

    return Stack(
      children: [
        // Fundo dinâmico com gradiente do tema
        Container(
          decoration: BoxDecoration(gradient: customColors.backgroundGradient),
        ),

        Scaffold(
          backgroundColor: Colors.transparent,
          body: LayoutBuilder(
            builder: (context, constraints) {
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Substituído pelo componente reutilizável AgroAppBar
                  AgroAppBar(title: 'Agromotion'),

                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.horizontalPadding,
                      vertical: 24,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Grid dinâmica de estatísticas
                        _buildDynamicGrid(
                          constraints.maxWidth,
                          theme.colorScheme,
                        ),

                        const SizedBox(height: 32),

                        // Botão de ação responsivo
                        _buildResponsiveButton(
                          context.isSmall,
                          theme,
                          customColors,
                        ),

                        // Espaçamento inferior para não ficar atrás da AgroNavBar
                        const SizedBox(height: 120),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicGrid(double width, ColorScheme colorScheme) {
    // Breakpoints: 2 colunas para mobile, 3 para tablet, 4 para ecrãs largos
    int crossAxisCount = width < 600 ? 2 : (width < 900 ? 3 : 4);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          'Bateria',
          '85%',
          Icons.battery_charging_full,
          colorScheme.primary,
          colorScheme,
        ),
        _buildStatCard(
          'Ração',
          '42kg',
          Icons.inventory_2,
          Colors.orangeAccent,
          colorScheme,
        ),
        _buildStatCard(
          'Velocidade',
          '2.4m/s',
          Icons.speed,
          Colors.blueAccent,
          colorScheme,
        ),
        _buildStatCard(
          'Área',
          '1.2ha',
          Icons.terrain,
          Colors.tealAccent,
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    ColorScheme colorScheme,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withAlpha(50),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveButton(
    bool isSmall,
    ThemeData theme,
    AppColorsExtension customColors,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    final Decoration buttonDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: isMoving
          ? theme.colorScheme.error.withAlpha(80)
          : (isDark ? null : theme.colorScheme.primary),
      gradient: (!isMoving && isDark)
          ? customColors.primaryButtonGradient
          : null,
    );

    return GlassContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => isMoving = !isMoving),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: isSmall ? 20 : 30),
            decoration: buttonDecoration,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isMoving ? Icons.stop_circle : Icons.play_circle,
                  // onPrimary é dinâmico: escuro no Dark, branco no Light
                  color: isMoving ? Colors.white : theme.colorScheme.onPrimary,
                  size: isSmall ? 24 : 32,
                ),
                const SizedBox(width: 12),
                Text(
                  isMoving ? 'PARAR OPERAÇÃO' : 'INICIAR ALIMENTAÇÃO',
                  style: TextStyle(
                    fontSize: isSmall ? 14 : 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: isMoving
                        ? Colors.white
                        : theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
