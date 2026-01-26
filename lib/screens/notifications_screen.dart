import 'package:agromotion/components/notifications/notification_tile.dart';
import 'package:agromotion/utils/responsive_layout.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header com botão de voltar
                SliverPadding(
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
                        // Botão Voltar Nativo
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          onPressed: () => Navigator.pop(context),
                          color: theme.colorScheme.onSurface,
                          iconSize: 20,
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Notificações",
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                  ),
                                  Text(
                                    "Tens 2 alertas pendentes",
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withAlpha(50),
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.done_all_rounded),
                                onPressed: () {},
                                tooltip: "Marcar todas como lidas",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Lista de Notificações
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.horizontalPadding,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SectionHeader(title: "Hoje"),
                      const NotificationTile(
                        title: "Bateria Crítica",
                        message:
                            "O robô está com 15% de bateria. A regressar à base.",
                        time: "agora",
                        type: NotificationType.error,
                      ),
                      const NotificationTile(
                        title: "Ciclo Concluído",
                        message:
                            "A alimentação do setor B foi finalizada com sucesso.",
                        time: "12:30",
                        type: NotificationType.success,
                      ),
                      const SectionHeader(title: "Ontem"),
                      const NotificationTile(
                        title: "Obstáculo Detetado",
                        message:
                            "O robô parou devido a um objeto no corredor central.",
                        time: "Ontem, 18:45",
                        type: NotificationType.warning,
                        isRead: true,
                      ),
                      const NotificationTile(
                        title: "Atualização de Sistema",
                        message:
                            "Versão 2.4.0 instalada com novas métricas de eficiência.",
                        time: "Ontem, 09:00",
                        type: NotificationType.info,
                        isRead: true,
                      ),
                      const SizedBox(height: 100),
                    ]),
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

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: Theme.of(context).colorScheme.primary.withAlpha(70),
        ),
      ),
    );
  }
}
