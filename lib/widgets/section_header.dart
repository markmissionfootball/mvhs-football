import 'package:flutter/material.dart';
import '../theme/diablo_colors.dart';
import 'diamond_divider.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: DiabloColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
            ),
            const Spacer(),
            if (onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'SEE ALL',
                  style: TextStyle(
                    color: DiabloColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const DiamondDivider(color: DiabloColors.gold),
        const SizedBox(height: 12),
      ],
    );
  }
}
