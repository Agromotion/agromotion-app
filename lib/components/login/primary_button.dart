import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: theme.primaryColor.withAlpha(150),
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 16,
              ),
            ),
    );
  }
}