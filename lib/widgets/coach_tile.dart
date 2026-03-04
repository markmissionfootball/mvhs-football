import 'package:flutter/material.dart';
import '../theme/diablo_colors.dart';

class CoachTile extends StatelessWidget {
  final String name;
  final String title;
  final String positionGroup;
  final bool isHeadCoach;

  const CoachTile({
    super.key,
    required this.name,
    required this.title,
    required this.positionGroup,
    this.isHeadCoach = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DiabloColors.darkCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Diamond icon
          Icon(
            Icons.diamond,
            color: isHeadCoach ? DiabloColors.gold : DiabloColors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          // Name, title, and position group
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: DiabloColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: DiabloColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  positionGroup,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.54),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
