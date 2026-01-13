import 'package:flutter/material.dart';

class AppDialogs {
  /// Diálogo de confirmação para remoção
  static Future<bool?> showDeleteConfirmation(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Horário?'),
        content: const Text(
          'O robô AgroMotion deixará de realizar esta tarefa automaticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.error,
            ),
            child: const Text('REMOVER'),
          ),
        ],
      ),
    );
  }
}
