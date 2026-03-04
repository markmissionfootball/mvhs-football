import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/diablo_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/empty_state.dart';

class StatsOverviewScreen extends ConsumerWidget {
  const StatsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(currentPlayerProvider);

    return Scaffold(
      backgroundColor: DiabloColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        title: const Text(
          'MY STATS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: playerAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DiabloColors.gold),
        ),
        error: (_, __) => const EmptyState(
          icon: Icons.error_outline,
          title: 'COULD NOT LOAD STATS',
          subtitle: 'Please try again later',
        ),
        data: (player) {
          if (player == null) {
            return const EmptyState(
              icon: Icons.bar_chart,
              title: 'NO STATS AVAILABLE',
              subtitle: 'Stats will appear once games are played',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Demo stat summary row
                Row(
                  children: const [
                    Expanded(
                      child: StatCard(
                        value: '7',
                        label: 'Games',
                        variant: StatCardVariant.red,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        value: '3',
                        label: 'TDs',
                        variant: StatCardVariant.gold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        value: '42',
                        label: 'Tackles',
                        variant: StatCardVariant.dark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Game log section
                const SectionHeader(title: 'GAME LOG'),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Game log will load from player stats',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
