import 'package:flutter/material.dart';
import '../theme/diablo_colors.dart';

class PlayerRosterTile extends StatelessWidget {
  final int? jerseyNumber;
  final String name;
  final String position;
  final int grade;
  final VoidCallback? onTap;

  const PlayerRosterTile({
    super.key,
    this.jerseyNumber,
    required this.name,
    required this.position,
    required this.grade,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DiabloColors.darkCard,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Jersey number in red circle
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: DiabloColors.red,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  jerseyNumber != null ? '$jerseyNumber' : '--',
                  style: const TextStyle(
                    color: DiabloColors.gold,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name and position/grade
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
                    '$position  \u2022  Grade $grade',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.54),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Chevron
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
