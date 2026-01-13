import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/add_schedule_sheet.dart';
import '../utils/dialogs.dart';
import '../services/schedule_service.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horários Programados'),
        centerTitle: true,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _scheduleService.getSchedulesStream(),
        builder: (context, snapshot) {
          // 1. Tratamento de Erro
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar horários: ${snapshot.error}'),
            );
          }

          // 2. Estado de Carregamento
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 3. Extração e Conversão dos Dados
          final data =
              snapshot.data?.snapshot.value as Map<dynamic, dynamic>? ?? {};

          final schedulesList = data.entries.map((e) {
            return {'id': e.key, ...Map<String, dynamic>.from(e.value as Map)};
          }).toList();

          // Ordenar por hora (ex: 07:00 vem antes de 18:00)
          schedulesList.sort(
            (a, b) => a['time'].toString().compareTo(b['time'].toString()),
          );

          // 4. Estado Vazio
          if (schedulesList.isEmpty) {
            return _buildEmptyState(colorScheme);
          }

          // 5. Lista de Horários
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: schedulesList.length,
            itemBuilder: (context, index) {
              final s = schedulesList[index];
              final String scheduleId = s['id'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Dismissible(
                  key: Key(scheduleId), // Usar o ID real do Firebase como chave
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    HapticFeedback.heavyImpact();
                    return await AppDialogs.showDeleteConfirmation(context);
                  },
                  onDismissed: (_) async {
                    await _scheduleService.deleteSchedule(scheduleId);
                    HapticFeedback.lightImpact();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Horário removido com sucesso'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  background: _buildDeleteBackground(colorScheme),
                  child: _buildScheduleCard(s, context),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleAddNewSchedule(context),
        label: const Text('Novo Horário'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  // --- Construção do Card de Horário ---
  Widget _buildScheduleCard(Map<String, dynamic> s, BuildContext context) {
    final bool isActive = s['active'] ?? false;
    final String createdBy = s['createdByEmail'] ?? 'Desconhecido';

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () async {
          // Passamos os dados atuais para edição
          final result = await AddScheduleSheet.show(context, initialData: s);
          if (result != null) {
            await _scheduleService.saveSchedule(result, id: s['id']);
          }
        },
        leading: Icon(
          Icons.alarm,
          color: isActive ? Colors.green : Colors.grey,
          size: 28,
        ),
        title: Text(
          s['time'] ?? '--:--',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s['days'] ?? 'Sem dias definidos'),
            const SizedBox(height: 4),
            Text(
              'Por: $createdBy',
              style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        trailing: Switch(
          value: isActive,
          onChanged: (val) async {
            HapticFeedback.lightImpact();
            await _scheduleService.toggleStatus(s['id'], val);
          },
        ),
      ),
    );
  }

  Widget _buildDeleteBackground(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(Icons.delete_outline, color: colorScheme.error),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          const Text(
            'Nenhum horário agendado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const Text(
            'Crie um horário para o robô atuar.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddNewSchedule(BuildContext context) async {
    final result = await AddScheduleSheet.show(context);
    if (result != null) {
      await _scheduleService.saveSchedule(result);
    }
  }
}
