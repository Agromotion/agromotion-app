import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddScheduleSheet extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const AddScheduleSheet({super.key, this.initialData});

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    Map<String, dynamic>? initialData,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddScheduleSheet(initialData: initialData),
    );
  }

  @override
  State<AddScheduleSheet> createState() => _AddScheduleSheetState();
}

class _AddScheduleSheetState extends State<AddScheduleSheet> {
  late TimeOfDay _selectedTime;
  late List<bool> _selectedDays;
  final List<String> _daysLabels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      // Modo Edição: Parse da string "HH:mm"
      final parts = widget.initialData!['time'].split(':');
      _selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );

      // Lógica de dias (se "Segunda a Domingo", seleciona todos)
      bool isAllDays = widget.initialData!['days'] == 'Segunda a Domingo';
      _selectedDays = List.generate(7, (_) => isAllDays);
    } else {
      // Modo Criação
      _selectedTime = const TimeOfDay(hour: 8, minute: 0);
      _selectedDays = List.generate(7, (_) => true);
    }
  }

  String _getDaysText() {
    int count = _selectedDays.where((day) => day).length;
    if (count == 7) return 'Segunda a Domingo';
    if (count == 0) return 'Nenhum dia selecionado';

    List<String> shortNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    List<String> activeDays = [];
    for (int i = 0; i < 7; i++) {
      if (_selectedDays[i]) activeDays.add(shortNames[i]);
    }
    return activeDays.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withAlpha(40),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            widget.initialData != null ? 'Editar Horário' : 'Novo Horário',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),

          GestureDetector(
            onTap: () async {
              HapticFeedback.mediumImpact();
              final TimeOfDay? time = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(alwaysUse24HourFormat: true),
                  child: child!,
                ),
              );
              if (time != null) setState(() => _selectedTime = time);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withAlpha(40),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.secondary.withAlpha(30)),
              ),
              child: Text(
                '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.secondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Repetir nos dias:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isSelected = _selectedDays[index];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDays[index] = !isSelected);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.secondary
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.secondary
                          : colorScheme.outlineVariant,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _daysLabels[index],
                      style: TextStyle(
                        color: isSelected
                            ? colorScheme.onSecondary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context, {
                  'time':
                      '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                  'days': _getDaysText(),
                  'active': widget.initialData?['active'] ?? true,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                widget.initialData != null
                    ? 'Guardar Alterações'
                    : 'Criar Horário',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
