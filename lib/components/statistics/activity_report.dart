import 'package:flutter/material.dart';
import '../glass_container.dart';

class ActivityReport extends StatelessWidget {
  final List<ActivityTile> activities;

  const ActivityReport({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 4,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: activities
          .map((activity) => _buildActivityTile(activity, context))
          .toList(),
    );
  }

  Widget _buildActivityTile(ActivityTile activity, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: 14,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  activity.title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withAlpha(70),
                  ),
                ),
              ),
              Icon(activity.icon, size: 16, color: activity.color),
            ],
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              activity.value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: activity.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityTile {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  ActivityTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
