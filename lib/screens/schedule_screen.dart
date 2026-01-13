import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Horários Programados')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: schedules.length,
        itemBuilder: (context, index) {
          final s = schedules[index];
          return Card(
            child: ListTile(
              leading: Icon(Icons.alarm, color: s['active'] ? Colors.green : Colors.grey),
              title: Text(s['time'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              subtitle: Text(s['days']),
              trailing: Switch(
                value: s['active'],
                onChanged: (val) => setState(() => s['active'] = val),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Novo Horário'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}