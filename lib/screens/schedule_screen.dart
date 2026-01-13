import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/add_schedule_sheet.dart';
import '../utils/dialogs.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final List<Map<String, dynamic>> schedules = [
    {'time': '07:00', 'active': true, 'days': 'Segunda a Domingo'},
    {'time': '18:00', 'active': true, 'days': 'Segunda a Domingo'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horários Programados'),
        centerTitle: true,
      ),
      body: schedules.isEmpty
          ? _buildEmptyState(colorScheme)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final s = schedules[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Dismissible(
                    key: UniqueKey(),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      HapticFeedback.heavyImpact();
                      // CHAMADA DO DIÁLOGO À PARTE
                      return await AppDialogs.showDeleteConfirmation(context);
                    },
                    onDismissed: (_) {
                      setState(() => schedules.removeAt(index));
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Horário removido'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    background: _buildDeleteBackground(colorScheme),
                    child: _buildScheduleCard(s, index, context),
                  ),
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

  // --- Widgets Auxiliares para manter o build() limpo ---

  Widget _buildScheduleCard(
    Map<String, dynamic> s,
    int index,
    BuildContext context,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () async {
          final result = await AddScheduleSheet.show(context, initialData: s);
          if (result != null) setState(() => schedules[index] = result);
        },
        leading: Icon(
          Icons.alarm,
          color: s['active'] ? Colors.green : Colors.grey,
        ),
        title: Text(
          s['time'],
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(s['days']),
        trailing: Switch(
          value: s['active'],
          onChanged: (val) {
            HapticFeedback.lightImpact();
            setState(() => s['active'] = val);
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
          const Text('Nenhum horário agendado', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Future<void> _handleAddNewSchedule(BuildContext context) async {
    final result = await AddScheduleSheet.show(context);
    if (result != null) {
      setState(() {
        schedules.add(result);
        schedules.sort((a, b) => a['time'].compareTo(b['time']));
      });
    }
  }
}
