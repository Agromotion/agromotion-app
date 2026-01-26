import 'package:agromotion/components/agro_loading.dart';
import 'package:agromotion/components/agro_appbar.dart';
import 'package:agromotion/components/glass_container.dart';
import 'package:agromotion/utils/responsive_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/schedule/add_schedule.dart';
import '../utils/dialogs.dart';
import '../services/schedule_service.dart';
import '../theme/app_theme.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ScheduleService _scheduleService = ScheduleService();

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
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _scheduleService.getSchedulesStream(),
            builder: (context, snapshot) {
              // 1. Estados de Erro e Carregamento
              if (snapshot.hasError) {
                return Center(child: Text('Erro: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: AgroLoading());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return CustomScrollView(
                  slivers: [
                    AgroAppBar(title: 'Horários'),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(colorScheme),
                    ),
                  ],
                );
              }

              // 2. Processamento Firestore
              final schedulesList = snapshot.data!.docs.map((doc) {
                return {'id': doc.id, ...doc.data()};
              }).toList();

              schedulesList.sort(
                (a, b) => a['time'].toString().compareTo(b['time'].toString()),
              );

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  AgroAppBar(title: 'Horários'),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      context.horizontalPadding,
                      24,
                      context.horizontalPadding,
                      140,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final s = schedulesList[index];
                        final String scheduleId = s['id'];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: Key(scheduleId),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              HapticFeedback.heavyImpact();
                              return await AppDialogs.showDeleteConfirmation(
                                context,
                              );
                            },
                            onDismissed: (_) async {
                              await _scheduleService.deleteSchedule(scheduleId);
                              HapticFeedback.lightImpact();
                            },
                            background: _buildDeleteBackground(colorScheme),
                            child: _buildScheduleCard(s, context, colorScheme),
                          ),
                        );
                      }, childCount: schedulesList.length),
                    ),
                  ),
                ],
              );
            },
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 90),
            child: FloatingActionButton.extended(
              onPressed: () => _handleAddNewSchedule(context),
              label: const Text('Novo Horário'),
              icon: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(
    Map<String, dynamic> s,
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final bool isActive = s['active'] ?? false;
    final String createdBy = s['createdByEmail'] ?? 'Desconhecido';

    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: () async {
          final result = await AddScheduleSheet.show(context, initialData: s);
          if (result != null) {
            await _scheduleService.saveSchedule(result, id: s['id']);
          }
        },
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.green.withAlpha(10)
                : Colors.grey.withAlpha(10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.alarm,
            color: isActive ? Colors.green : Colors.grey,
            size: 24,
          ),
        ),
        title: Text(
          s['time'] ?? '--:--',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (s['days'] is List)
                  ? (s['days'] as List).join(', ')
                  : s['days'] ?? 'Sem dias definidos',
              style: TextStyle(color: colorScheme.onSurface.withAlpha(70)),
            ),
            Text(
              'Por: ${createdBy.split('@')[0]}',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurface.withAlpha(40),
              ),
            ),
          ],
        ),
        trailing: Switch(
          activeThumbColor: Colors.green,
          value: isActive,
          onChanged: (val) async {
            HapticFeedback.lightImpact();
            await _scheduleService.toggleStatus(
              s['id'],
              val,
              s['time'] ?? '--:--',
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeleteBackground(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.error.withAlpha(20),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.error.withAlpha(50)),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(Icons.delete_sweep_outlined, color: colorScheme.error),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: 64,
          color: colorScheme.onSurface.withAlpha(20),
        ),
        const SizedBox(height: 16),
        const Text(
          'Sem agendamentos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Adicione um horário para começar.',
          style: TextStyle(color: colorScheme.onSurface.withAlpha(50)),
        ),
      ],
    );
  }

  Future<void> _handleAddNewSchedule(BuildContext context) async {
    final result = await AddScheduleSheet.show(context);
    if (result != null) {
      await _scheduleService.saveSchedule(result);
    }
  }
}
