import 'package:flutter/material.dart';

class DiamondDivider extends StatelessWidget {
  final Color color;
  final double lineWidth;
  final double diamondSize;
  final MainAxisAlignment alignment;

  const DiamondDivider({
    super.key,
    this.color = Colors.white54,
    this.lineWidth = 60,
    this.diamondSize = 14,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      children: [
        Container(
          width: lineWidth,
          height: 1,
          color: color,
        ),
        Transform.rotate(
          angle: 0.785398, // 45 degrees
          child: Container(
            width: diamondSize,
            height: diamondSize,
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 1),
            ),
          ),
        ),
        Container(
          width: lineWidth,
          height: 1,
          color: color,
        ),
      ],
    );
  }
}
