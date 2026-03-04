import 'package:flutter/material.dart';
import '../../theme/diablo_colors.dart';
import '../../widgets/empty_state.dart';

class AwardsScreen extends StatelessWidget {
  const AwardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiabloColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        title: const Text(
          'AWARDS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: const EmptyState(
        icon: Icons.emoji_events,
        title: 'NO AWARDS YET',
        subtitle: 'Awards will appear here after games',
      ),
    );
  }
}
