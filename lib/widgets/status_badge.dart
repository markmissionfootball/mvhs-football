import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
  });

  const StatusBadge.win({super.key})
      : label = 'W',
        color = const Color(0xFF4CAF50),
        textColor = null;

  const StatusBadge.loss({super.key})
      : label = 'L',
        color = const Color(0xFFD12132),
        textColor = null;

  const StatusBadge.home({super.key})
      : label = 'HOME',
        color = const Color(0xFFFCB423),
        textColor = null;

  const StatusBadge.away({super.key})
      : label = 'AWAY',
        color = const Color(0xB3FFFFFF),
        textColor = null;

  const StatusBadge.upcoming({super.key})
      : label = 'UPCOMING',
        color = const Color(0xFFFCB423),
        textColor = null;

  @override
  Widget build(BuildContext context) {
    final displayColor = textColor ?? color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: displayColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
