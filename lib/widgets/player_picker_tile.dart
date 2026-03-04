import 'package:flutter/material.dart';
import '../theme/diablo_colors.dart';

class PlayerPickerTile extends StatelessWidget {
  final String playerName;
  final String? position;
  final bool isSelected;
  final VoidCallback onTap;

  const PlayerPickerTile({
    super.key,
    required this.playerName,
    this.position,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? DiabloColors.red.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? DiabloColors.gold : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? DiabloColors.gold
                      : Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: DiabloColors.dark)
                  : null,
            ),
            const SizedBox(width: 14),
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: DiabloColors.red,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  playerName.isNotEmpty ? playerName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + position
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (position != null)
                    Text(
                      position!,
                      style: TextStyle(
                        color: DiabloColors.gold.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
