import 'package:flutter/material.dart';
import '../theme/diablo_colors.dart';
import 'diamond_divider.dart';

enum StatCardVariant { red, gold, dark }

class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final StatCardVariant variant;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.variant = StatCardVariant.red,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = variant == StatCardVariant.dark;
    final isRed = variant == StatCardVariant.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: isDark ? null : (isRed ? DiabloColors.redGradient : DiabloColors.goldGradient),
        color: isDark ? DiabloColors.darkCard : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          DiamondDivider(
            color: isDark ? Colors.white24 : (isRed ? Colors.white54 : Colors.black38),
          ),
          const SizedBox(height: 16),
          Text(
            '$value $label'.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              letterSpacing: 2.0,
              color: isDark ? Colors.white : (isRed ? Colors.white : DiabloColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
